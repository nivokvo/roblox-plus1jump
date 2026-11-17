local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BASE_HEIGHT = 5
local HEIGHT_PER_JUMP = 0.25
local WIN_BONUS = 1
local AUTOSAVE_SECONDS = 60

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local jumpGained = remotes:WaitForChild("JumpGained")
local wonEvent = remotes:WaitForChild("Won")
local track = workspace:WaitForChild("Track")
local checkpoints = track:WaitForChild("Checkpoints")
local winPad = track:WaitForChild("WinPad")

local store
local ok = pcall(function()
	store = DataStoreService:GetDataStore("PlusOneJump_v1")
end)
if not ok then
	warn("DataStore unavailable, progress will not save")
end

local function multiplier(player)
	return 1 + player.leaderstats.Wins.Value * WIN_BONUS
end

local function applyJump(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid.UseJumpPower = false
	humanoid.JumpHeight = BASE_HEIGHT + player.leaderstats.Jump.Value * HEIGHT_PER_JUMP
end

local function load(player)
	local data
	if store then
		local success, result = pcall(function()
			return store:GetAsync("u" .. player.UserId)
		end)
		if success then
			data = result
		else
			warn("Load failed for", player.Name, result)
		end
	end
	return data or {}
end

local function save(player)
	local stats = player:FindFirstChild("leaderstats")
	if not store or not stats or not player:GetAttribute("Loaded") then
		return
	end
	local payload = {
		Jump = stats.Jump.Value,
		Wins = stats.Wins.Value,
		Stage = stats.Stage.Value,
	}
	local success, err = pcall(function()
		store:SetAsync("u" .. player.UserId, payload)
	end)
	if not success then
		warn("Save failed for", player.Name, err)
	end
end

local function spawnAtStage(player, character)
	local stage = player.leaderstats.Stage.Value
	local cp = checkpoints:FindFirstChild(tostring(stage))
	if cp then
		task.defer(function()
			character:PivotTo(cp.CFrame + Vector3.new(0, 4, 0))
		end)
	end
end

Players.PlayerAdded:Connect(function(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, name in ipairs({ "Jump", "Wins", "Stage" }) do
		local v = Instance.new("IntValue")
		v.Name = name
		v.Parent = stats
	end
	stats.Parent = player

	local data = load(player)
	stats.Jump.Value = data.Jump or 0
	stats.Wins.Value = data.Wins or 0
	stats.Stage.Value = data.Stage or 0
	player:SetAttribute("Loaded", true)

	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid")
		applyJump(player)
		spawnAtStage(player, character)
	end)
	if player.Character then
		applyJump(player)
	end
end)

Players.PlayerRemoving:Connect(save)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(save, player)
	end
	task.wait(2)
end)

local function playerFromHit(hit)
	local character = hit:FindFirstAncestorOfClass("Model")
	return character and Players:GetPlayerFromCharacter(character)
end

for _, cp in ipairs(checkpoints:GetChildren()) do
	local stage = cp:GetAttribute("Stage")
	cp.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if player and player:FindFirstChild("leaderstats") and player.leaderstats.Stage.Value < stage then
			player.leaderstats.Stage.Value = stage
		end
	end)
end

local winCooldown = {}
winPad.Touched:Connect(function(hit)
	local player = playerFromHit(hit)
	if not player or winCooldown[player] or not player:FindFirstChild("leaderstats") then
		return
	end
	winCooldown[player] = true
	local stats = player.leaderstats
	stats.Wins.Value += 1
	stats.Jump.Value = 0
	stats.Stage.Value = 0
	wonEvent:FireClient(player, stats.Wins.Value, multiplier(player))
	task.wait(2)
	player:LoadCharacter()
	task.wait(1)
	winCooldown[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local stats = player:FindFirstChild("leaderstats")
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if stats and humanoid and humanoid.Health > 0 then
				local gain = math.floor(multiplier(player))
				stats.Jump.Value += gain
				applyJump(player)
				jumpGained:FireClient(player, gain)
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_SECONDS)
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(save, player)
		end
	end
end)
