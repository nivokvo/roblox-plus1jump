local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local walls = workspace:WaitForChild("Track"):WaitForChild("Walls")
local stats = player:WaitForChild("leaderstats")

local gui = Instance.new("ScreenGui")
gui.Name = "JumpHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function makeLabel(props)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0
	t.TextScaled = true
	for k, v in pairs(props) do
		t[k] = v
	end
	t.Parent = gui
	return t
end

local jumpLabel = makeLabel({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.new(0.5, 0, 0, 56),
	TextColor3 = Color3.fromRGB(255, 230, 90),
})
local infoLabel = makeLabel({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 64),
	Size = UDim2.new(0.6, 0, 0, 30),
})

local function nextWallNeed()
	local stage = stats.Stage.Value
	local wall = walls:FindFirstChild("Wall" .. (stage + 1))
	return wall and wall:GetAttribute("RequiredJump")
end

local function refresh()
	local mult = 1 + stats.Wins.Value
	jumpLabel.Text = "JUMP " .. stats.Jump.Value
	local need = nextWallNeed()
	local nextText = need and ("Next wall: " .. need) or "Go to the WIN pad!"
	infoLabel.Text = string.format("x%d  |  Wins %d  |  %s", mult, stats.Wins.Value, nextText)
end

for _, name in ipairs({ "Jump", "Wins", "Stage" }) do
	stats:WaitForChild(name).Changed:Connect(refresh)
end
refresh()

remotes.JumpGained.OnClientEvent:Connect(function(amount)
	local pop = makeLabel({
		Text = "+" .. amount,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5 + (math.random() - 0.5) * 0.2, 0, 0.55, 0),
		Size = UDim2.new(0, 120, 0, 60),
		TextColor3 = Color3.fromRGB(120, 255, 120),
	})
	local tween = TweenService:Create(pop, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = pop.Position - UDim2.new(0, 0, 0.15, 0),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		pop:Destroy()
	end)
end)

remotes.Won.OnClientEvent:Connect(function(wins, mult)
	local banner = makeLabel({
		Text = string.format("YOU WIN! Wins: %d\nJump reset, now x%d speed", wins, mult),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromScale(0.7, 0.2),
		TextColor3 = Color3.fromRGB(255, 215, 0),
	})
	task.delay(3, function()
		banner:Destroy()
	end)
end)
