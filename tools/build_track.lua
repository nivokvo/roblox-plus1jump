local RS = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local old = workspace:FindFirstChild("Track") if old then old:Destroy() end

local HEIGHTS = {10, 20, 35, 55, 80, 110, 150, 200, 260, 330}
local COLORS = {
	Color3.fromRGB(255, 89, 94), Color3.fromRGB(255, 146, 76), Color3.fromRGB(255, 202, 58),
	Color3.fromRGB(138, 201, 38), Color3.fromRGB(82, 196, 160), Color3.fromRGB(25, 130, 196),
	Color3.fromRGB(106, 76, 147), Color3.fromRGB(241, 91, 181), Color3.fromRGB(0, 187, 249),
	Color3.fromRGB(255, 215, 0),
}
local WIDTH, THICK, GAP, START_Z = 40, 12, 70, 60
local BASE_HEIGHT, PER_JUMP = 5, 0.25

local track = Instance.new("Folder") track.Name = "Track" track.Parent = workspace
local walls = Instance.new("Folder") walls.Name = "Walls" walls.Parent = track
local checkpoints = Instance.new("Folder") checkpoints.Name = "Checkpoints" checkpoints.Parent = track

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do p[k] = v end
	return p
end

local function label(parent, face, text, color)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 20
	sg.Parent = parent
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0
	t.Parent = sg
	return sg
end

local z = START_Z
for i, h in ipairs(HEIGHTS) do
	local need = math.ceil((h + 1 - BASE_HEIGHT) / PER_JUMP)
	local wall = part({
		Name = "Wall" .. i, Size = Vector3.new(WIDTH, h, THICK),
		Position = Vector3.new(0, h / 2, z), Color = COLORS[i], Material = Enum.Material.SmoothPlastic,
		Parent = walls,
	})
	wall:SetAttribute("Stage", i)
	wall:SetAttribute("RequiredJump", need)
	part({
		Name = "Trim", Size = Vector3.new(WIDTH + 0.4, 1, THICK + 0.4),
		Position = Vector3.new(0, h + 0.5, z), Color = Color3.new(1, 1, 1),
		Material = Enum.Material.Neon, Parent = wall,
	})
	local sign = part({
		Name = "Sign", Size = Vector3.new(24, 10, 0.5), Transparency = 1, CanCollide = false,
		Position = Vector3.new(0, math.min(h, 14) / 2 + 3, z - THICK / 2 - 0.4), Parent = wall,
	})
	label(sign, Enum.NormalId.Front, "WALL " .. i .. "\nNEED " .. need .. " JUMP")

	local cp = part({
		Name = tostring(i), Size = Vector3.new(14, 1, 14),
		Position = Vector3.new(0, 0.5, z + THICK / 2 + 28), Color = COLORS[i],
		Material = Enum.Material.Neon, CanCollide = true, Parent = checkpoints,
	})
	cp:SetAttribute("Stage", i)
	label(cp, Enum.NormalId.Top, "CHECKPOINT " .. i, Color3.new(1, 1, 1))
	z += GAP
end

local win = part({
	Name = "WinPad", Size = Vector3.new(30, 1.2, 30),
	Position = Vector3.new(0, 0.6, z + 10), Color = Color3.fromRGB(255, 215, 0),
	Material = Enum.Material.Neon, Parent = track,
})
label(win, Enum.NormalId.Top, "WIN!", Color3.fromRGB(40, 20, 0))
local sparkle = Instance.new("ParticleEmitter")
sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
sparkle.Rate = 40 sparkle.Lifetime = NumberRange.new(1.5, 2.5) sparkle.Speed = NumberRange.new(8, 16)
sparkle.SpreadAngle = Vector2.new(40, 40) sparkle.Parent = win

local endZ = z + 40
local length = endZ - 20
for _, x in ipairs({-WIDTH / 2 - 1, WIDTH / 2 + 1}) do
	part({
		Name = "SideBarrier", Size = Vector3.new(2, 600, length), Transparency = 0.85,
		Color = Color3.fromRGB(180, 220, 255), Material = Enum.Material.Glass,
		Position = Vector3.new(x, 300, 20 + length / 2), Parent = track,
	})
end
part({
	Name = "EndBarrier", Size = Vector3.new(WIDTH + 4, 600, 2), Transparency = 0.85,
	Color = Color3.fromRGB(180, 220, 255), Material = Enum.Material.Glass,
	Position = Vector3.new(0, 300, endZ), Parent = track,
})

local title = part({
	Name = "TitleSign", Size = Vector3.new(40, 12, 1), Transparency = 1, CanCollide = false,
	Position = Vector3.new(0, 22, 25), Parent = track,
})
label(title, Enum.NormalId.Front, "+1 JUMP EVERY SECOND", Color3.fromRGB(255, 230, 90))

local spawn = workspace:FindFirstChild("SpawnLocation")
if spawn then spawn.Position = Vector3.new(0, 0.5, 0) spawn.Orientation = Vector3.new(0, 180, 0) end
workspace.Baseplate.Color = Color3.fromRGB(99, 176, 88)
workspace.Baseplate.Material = Enum.Material.Grass

local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes" remotes.Parent = RS
for _, n in ipairs({"JumpGained", "Won"}) do
	if not remotes:FindFirstChild(n) then
		local e = Instance.new("RemoteEvent") e.Name = n e.Parent = remotes
	end
end

Lighting.ClockTime = 14
return "track built, win pad at z=" .. (z + 10)
