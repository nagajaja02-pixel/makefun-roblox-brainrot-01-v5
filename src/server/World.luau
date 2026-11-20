-- World: builds the whole island — ground, conveyor, walls, six safehouses,
-- harbor decor (crane, containers, ship, observation deck, leaderboard board),
-- spawn pads and signs. build() runs once at server start and returns the
-- table of references the services work with: bases, conveyor, board, spots.

local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)

local World = {}

local function makePart(parent, name, size, pos, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = pos
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Shape = shape or Enum.PartType.Block
	part.Anchored = true
	part.CanCollide = true
	part.Parent = parent
	return part
end

-- A board with a SurfaceGui face: a title line plus up to three text lines.
-- Used for base signs and the leaderboard board.
local function makeBoard(parent, name, size, pos, title, lines)
	local board = makePart(parent, name, size, pos, Color3.fromRGB(93, 64, 55), Enum.Material.Wood)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "BoardGui"
	gui.Face = Enum.NormalId.Front
	gui.Parent = board
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "BoardTitle"
	titleLabel.Size = UDim2.new(1, 0, 0.3, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextColor3 = Color3.fromRGB(255, 235, 59)
	titleLabel.TextStrokeTransparency = 0.1
	titleLabel.Parent = gui
	for i, line in ipairs(lines) do
		local row = Instance.new("TextLabel")
		row.Name = "BoardLine" .. tostring(i)
		row.Size = UDim2.new(1, 0, 0.22, 0)
		row.Position = UDim2.new(0, 0, 0.28 + (i - 1) * 0.22, 0)
		row.BackgroundTransparency = 1
		row.Text = line
		row.TextScaled = true
		row.Font = Enum.Font.Gotham
		row.TextColor3 = Color3.fromRGB(255, 255, 255)
		row.TextStrokeTransparency = 0.1
		row.Parent = gui
	end
	return board, gui
end

-- One accent colour per safehouse so the six bases read as distinct
-- buildings instead of identical grey boxes.
local BASE_ACCENTS = {
	Color3.fromRGB(244, 67, 54), -- bright red
	Color3.fromRGB(33, 150, 243), -- bright blue
	Color3.fromRGB(76, 175, 80), -- bright green
	Color3.fromRGB(255, 193, 7), -- bright yellow
	Color3.fromRGB(156, 39, 176), -- bright purple
	Color3.fromRGB(0, 188, 212), -- bright teal
}

-- One safehouse: platform, back and side walls, ten stand pads in two rows
-- of five, a shield shell (invisible and non-solid until activated), and a
-- sign board at the front. Returns the base record the services use.
local function buildBase(parent, index, pos)
	local base = Instance.new("Model")
	base.Name = "Base" .. tostring(index)
	base.Parent = parent
	local accent = BASE_ACCENTS[((index - 1) % #BASE_ACCENTS) + 1]
	-- Brick walls in the base accent colour and a concrete platform, so
	-- the building reads as a real structure instead of flat plastic.
	makePart(base, "Platform", Vector3.new(24, 1, 28), Vector3.new(pos.X, 0.5, pos.Z), Color3.fromRGB(224, 228, 232), Enum.Material.Concrete)
	makePart(base, "BackWall", Vector3.new(24, 8, 1), Vector3.new(pos.X, 4.5, pos.Z + 13.5), accent, Enum.Material.Brick)
	makePart(base, "SideWallLeft", Vector3.new(1, 8, 28), Vector3.new(pos.X - 11.5, 4.5, pos.Z), accent, Enum.Material.Brick)
	makePart(base, "SideWallRight", Vector3.new(1, 8, 28), Vector3.new(pos.X + 11.5, 4.5, pos.Z), accent, Enum.Material.Brick)
	-- Flat roof slab overhanging the walls, in clean light grey.
	makePart(base, "Roof", Vector3.new(26, 1, 30), Vector3.new(pos.X, 9, pos.Z), accent, Enum.Material.SmoothPlastic)
	-- Bright trim band along the top of each wall.
	makePart(base, "TrimBack", Vector3.new(24, 0.5, 1.2), Vector3.new(pos.X, 8.2, pos.Z + 13.5), Color3.fromRGB(255, 213, 79), Enum.Material.Metal)
	makePart(base, "TrimLeft", Vector3.new(1.2, 0.5, 28), Vector3.new(pos.X - 11.5, 8.2, pos.Z), Color3.fromRGB(255, 213, 79), Enum.Material.Metal)
	makePart(base, "TrimRight", Vector3.new(1.2, 0.5, 28), Vector3.new(pos.X + 11.5, 8.2, pos.Z), Color3.fromRGB(255, 213, 79), Enum.Material.Metal)
	-- Light-blue glass windows on the back wall and a light wooden door.
	makePart(base, "WindowLeft", Vector3.new(4, 3, 0.2), Vector3.new(pos.X - 6, 5.5, pos.Z + 12.85), Color3.fromRGB(135, 206, 235), Enum.Material.Glass)
	makePart(base, "WindowRight", Vector3.new(4, 3, 0.2), Vector3.new(pos.X + 6, 5.5, pos.Z + 12.85), Color3.fromRGB(135, 206, 235), Enum.Material.Glass)
	makePart(base, "Door", Vector3.new(4, 6, 0.3), Vector3.new(pos.X, 3.5, pos.Z + 12.8), Color3.fromRGB(176, 141, 87), Enum.Material.Wood)
	-- A window on the outside of each side wall.
	makePart(base, "WindowSideLeft", Vector3.new(0.2, 3, 4), Vector3.new(pos.X - 12.05, 5.5, pos.Z), Color3.fromRGB(135, 206, 235), Enum.Material.Glass)
	makePart(base, "WindowSideRight", Vector3.new(0.2, 3, 4), Vector3.new(pos.X + 12.05, 5.5, pos.Z), Color3.fromRGB(135, 206, 235), Enum.Material.Glass)
	-- Ten stand pads: two rows of five across the platform.
	local pads = {}
	for row = 0, 1 do
		for col = 0, 4 do
			local slot = row * 5 + col + 1
			local padPos = Vector3.new(pos.X - 8 + col * 4, 1.15, pos.Z - 6 + row * 7)
			local pad = makePart(base, "StandPad" .. tostring(slot), Vector3.new(3, 0.3, 3), padPos, Color3.fromRGB(255, 213, 79), Enum.Material.Neon, Enum.PartType.Cylinder)
			pad.CanCollide = false
			table.insert(pads, padPos)
		end
	end
	-- Shield shell: a transparent cylinder around the base, off until used.
	local shell = makePart(base, "ShieldShell", Vector3.new(26, 10, 30), Vector3.new(pos.X, 5.5, pos.Z), Color3.fromRGB(41, 182, 246), Enum.Material.ForceField, Enum.PartType.Cylinder)
	shell.Transparency = 1
	shell.CanCollide = false
	shell.CollisionGroup = "Shield"
	-- Sign at the front of the base.
	local signPos = Vector3.new(pos.X, 3.5, pos.Z - 14.5)
	local _, signGui = makeBoard(base, "BaseSign", Vector3.new(10, 5, 0.5), signPos, "BASE " .. tostring(index), { "Unclaimed", "Stand here to claim" })
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "BaseSpawn" .. tostring(index)
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(pos.X, 1.5, pos.Z + 10)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = base
	return {
		index = index,
		position = pos,
		model = base,
		pads = pads,
		shell = shell,
		signGui = signGui,
		spawn = spawn,
	}
end

function World.build()
	local folder = Instance.new("Folder")
	folder.Name = "BrainrotWorld"
	folder.Parent = workspace

	-- Sea around the island, bright cyan-blue so the harbour reads as a harbour.
	makePart(folder, "Sea", Vector3.new(500, 1, 500), Vector3.new(0, -2.5, 0), Color3.fromRGB(0, 176, 222), Enum.Material.Water)
	-- Island ground: one uniform bright-grass top layer sitting clearly
	-- above the sand base (grass top Y 0.05 vs sand top Y 0), so the whole
	-- top reads as pure grass with no flicker; the sand only shows as a
	-- beach rim around the edge.
	makePart(folder, "SandBase", Vector3.new(268, 2, 200), Vector3.new(0, -1, 0), Color3.fromRGB(194, 178, 128), Enum.Material.Sand)
	makePart(folder, "GrassTop", Vector3.new(260, 0.4, 192), Vector3.new(0, -0.15, 0), Color3.fromRGB(88, 205, 100), Enum.Material.Grass)
	-- Boundary walls around the island, in warm tan brick.
	makePart(folder, "WallNorth", Vector3.new(268, 6, 1), Vector3.new(0, 3, -99.5), Color3.fromRGB(201, 170, 125), Enum.Material.Brick)
	makePart(folder, "WallSouth", Vector3.new(268, 6, 1), Vector3.new(0, 3, 99.5), Color3.fromRGB(201, 170, 125), Enum.Material.Brick)
	makePart(folder, "WallWest", Vector3.new(1, 6, 200), Vector3.new(-133.5, 3, 0), Color3.fromRGB(201, 170, 125), Enum.Material.Brick)
	makePart(folder, "WallEast", Vector3.new(1, 6, 200), Vector3.new(133.5, 3, 0), Color3.fromRGB(201, 170, 125), Enum.Material.Brick)
	-- Bright footpaths flanking the conveyor, under the lamp posts.
	makePart(folder, "PathNorth", Vector3.new(240, 0.2, 4), Vector3.new(0, 0.1, 8), Color3.fromRGB(238, 228, 196), Enum.Material.Cobblestone)
	makePart(folder, "PathSouth", Vector3.new(240, 0.2, 4), Vector3.new(0, 0.1, -8), Color3.fromRGB(238, 228, 196), Enum.Material.Cobblestone)

	-- Conveyor: a long, wide, near-black belt down the middle of the
	-- island, with bright yellow side rails and glowing lane markings,
	-- running from X -131 to +131. The dark belt against the bright
	-- grass makes it the easiest thing to spot on the island.
	makePart(folder, "Belt", Vector3.new(262, 1, 6), Vector3.new(0, 0.5, 0), Color3.fromRGB(28, 30, 33), Enum.Material.Metal)
	makePart(folder, "RailLeft", Vector3.new(262, 0.6, 0.5), Vector3.new(0, 1.1, -3.2), Color3.fromRGB(255, 213, 79), Enum.Material.Metal)
	makePart(folder, "RailRight", Vector3.new(262, 0.6, 0.5), Vector3.new(0, 1.1, 3.2), Color3.fromRGB(255, 213, 79), Enum.Material.Metal)
	-- Bright lane markings down the middle of the dark belt.
	makePart(folder, "BeltMarkLeft", Vector3.new(258, 0.1, 0.4), Vector3.new(0, 1.08, -2), Color3.fromRGB(255, 235, 59), Enum.Material.Neon)
	makePart(folder, "BeltMarkRight", Vector3.new(258, 0.1, 0.4), Vector3.new(0, 1.08, 2), Color3.fromRGB(255, 235, 59), Enum.Material.Neon)
	for x = -120, 120, 30 do
		makePart(folder, "BeltLeg", Vector3.new(1, 1, 5), Vector3.new(x, 0.5, 0), Color3.fromRGB(55, 65, 72), Enum.Material.Metal)
	end
	makePart(folder, "RollerWest", Vector3.new(1, 2, 6), Vector3.new(-131, 1, 0), Color3.fromRGB(70, 85, 95), Enum.Material.Metal, Enum.PartType.Cylinder)
	makePart(folder, "RollerEast", Vector3.new(1, 2, 6), Vector3.new(131, 1, 0), Color3.fromRGB(70, 85, 95), Enum.Material.Metal, Enum.PartType.Cylinder)

	-- Six safehouses at the positions BrainrotData defines.
	local bases = {}
	for i, pos in ipairs(BrainrotData.BasePositions) do
		bases[i] = buildBase(folder, i, pos)
	end

	-- Harbour crane near the west dock: tower, jib, and a hanging hook.
	makePart(folder, "CraneTower", Vector3.new(4, 26, 4), Vector3.new(-110, 13, -70), Color3.fromRGB(255, 214, 0), Enum.Material.Metal)
	makePart(folder, "CraneJib", Vector3.new(26, 2, 2), Vector3.new(-98, 25, -70), Color3.fromRGB(255, 214, 0), Enum.Material.Metal)
	makePart(folder, "CraneCable", Vector3.new(0.3, 8, 0.3), Vector3.new(-88, 21, -70), Color3.fromRGB(38, 50, 56))
	makePart(folder, "CraneHook", Vector3.new(3, 2, 3), Vector3.new(-88, 16.5, -70), Color3.fromRGB(255, 213, 79), Enum.Material.Metal)

	-- Colourful container stacks near the crane.
	local containerColors = {
		Color3.fromRGB(239, 83, 80),
		Color3.fromRGB(66, 165, 245),
		Color3.fromRGB(102, 187, 106),
		Color3.fromRGB(255, 213, 79),
	}
	local ci = 1
	for _, spot in ipairs({ Vector3.new(-100, 0, -80), Vector3.new(-88, 0, -84), Vector3.new(100, 0, 80) }) do
		for level = 0, 1 do
			makePart(folder, "Container", Vector3.new(12, 4, 6), Vector3.new(spot.X, 2 + level * 4, spot.Z), containerColors[ci], Enum.Material.Metal)
			ci = ci + 1
			if ci > #containerColors then
				ci = 1
			end
		end
	end

	-- A small ship at the south dock, floating on the sea.
	makePart(folder, "ShipHull", Vector3.new(22, 4, 9), Vector3.new(40, -0.5, -108), Color3.fromRGB(121, 85, 72), Enum.Material.Wood)
	makePart(folder, "ShipCabin", Vector3.new(8, 5, 7), Vector3.new(36, 4, -108), Color3.fromRGB(240, 230, 210), Enum.Material.WoodPlanks)
	makePart(folder, "ShipMast", Vector3.new(0.8, 14, 0.8), Vector3.new(44, 8, -108), Color3.fromRGB(93, 64, 55), Enum.Material.Wood)
	makePart(folder, "ShipFlag", Vector3.new(4, 2, 0.2), Vector3.new(46, 14, -108), Color3.fromRGB(239, 83, 80))

	-- Observation deck in the north-east corner: a raised platform with steps.
	makePart(folder, "DeckFloor", Vector3.new(18, 1, 18), Vector3.new(110, 8, 70), Color3.fromRGB(141, 110, 99), Enum.Material.Wood)
	makePart(folder, "DeckPost1", Vector3.new(1, 8, 1), Vector3.new(102, 4, 62), Color3.fromRGB(93, 64, 55), Enum.Material.Wood)
	makePart(folder, "DeckPost2", Vector3.new(1, 8, 1), Vector3.new(118, 4, 62), Color3.fromRGB(93, 64, 55), Enum.Material.Wood)
	makePart(folder, "DeckPost3", Vector3.new(1, 8, 1), Vector3.new(102, 4, 78), Color3.fromRGB(93, 64, 55), Enum.Material.Wood)
	makePart(folder, "DeckPost4", Vector3.new(1, 8, 1), Vector3.new(118, 4, 78), Color3.fromRGB(93, 64, 55), Enum.Material.Wood)
	for step = 0, 7 do
		makePart(folder, "DeckStep", Vector3.new(4, 1, 1.5), Vector3.new(110, 0.5 + step, 60 + step * 1.2), Color3.fromRGB(161, 136, 127), Enum.Material.Wood)
	end

	-- Leaderboard board near the middle of the island, facing the conveyor.
	local board, boardGui = makeBoard(folder, "LeaderboardBoard", Vector3.new(12, 14, 1), Vector3.new(0, 7, 25), "RICHEST PLAYERS", { "1. ---", "2. ---", "3. ---" })

	-- A few palm trees for harbour flavour.
	for _, spot in ipairs({ Vector3.new(-60, 0, 70), Vector3.new(60, 0, -70), Vector3.new(-120, 0, 40), Vector3.new(120, 0, -40) }) do
		makePart(folder, "PalmTrunk", Vector3.new(1.2, 9, 1.2), Vector3.new(spot.X, 4.5, spot.Z), Color3.fromRGB(121, 85, 72), Enum.Material.Wood, Enum.PartType.Cylinder)
		makePart(folder, "PalmTop", Vector3.new(5, 2.5, 5), Vector3.new(spot.X, 9.5, spot.Z), Color3.fromRGB(46, 125, 50), Enum.Material.Grass, Enum.PartType.Ball)
	end

	-- Lamp posts along the conveyor for a bright, readable island.
	for x = -90, 90, 45 do
		makePart(folder, "LampPost", Vector3.new(0.6, 7, 0.6), Vector3.new(x, 3.5, 8), Color3.fromRGB(38, 50, 56), Enum.Material.Metal)
		local lamp = makePart(folder, "LampHead", Vector3.new(1.5, 1, 1.5), Vector3.new(x, 7.5, 8), Color3.fromRGB(255, 241, 118), Enum.Material.Neon, Enum.PartType.Ball)
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 241, 118)
		light.Range = 12
		light.Brightness = 1
		light.Parent = lamp
	end

	return {
		folder = folder,
		bases = bases,
		conveyor = { minX = BrainrotData.Conveyor.minX, maxX = BrainrotData.Conveyor.maxX, beltY = 1.5 },
		board = board,
		boardGui = boardGui,
		merchantSpot = Vector3.new(20, 0, -30),
		deckTop = Vector3.new(110, 8.5, 70),
	}
end

return World
