-- BrainrotModels: builds the 3D model of one brainrot character from parts.
-- Every model faces -Z, stands on Y 0, carries a readable name label, and
-- gets a glowing trim when it carries a mutation. The conveyor and the
-- safehouse stands both ask this module for models, so the same character
-- always looks the same wherever it appears.

local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)

local BrainrotModels = {}

local function addPart(model, name, size, pos, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = pos
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Shape = shape or Enum.PartType.Block
	part.Anchored = true
	part.CanCollide = false
	part.Parent = model
	return part
end

-- Two eyes on the front face (-Z), so every character has a face.
local function addEyes(model, y)
	addPart(model, "EyeLeft", Vector3.new(0.28, 0.28, 0.1), Vector3.new(-0.35, y, -0.62), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	addPart(model, "EyeRight", Vector3.new(0.28, 0.28, 0.1), Vector3.new(0.35, y, -0.62), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
end

-- A theme feature per character, built from a few parts. Each one is shaped
-- after the name, so the cast reads at a glance: log, doll, fish, cactus,
-- fridge, banana, ice, tutu, coffee, pineapple, ringed cow, shark, bomber
-- crocodile, sky giraffe, banana dolphin, grape jellyfish.
local function addFeature(model, id, color)
	if id == "tungtung" then
		addPart(model, "LogTop", Vector3.new(1.6, 0.5, 1.0), Vector3.new(0, 3.9, 0), Color3.fromRGB(101, 67, 33))
		addPart(model, "LogKnob", Vector3.new(0.4, 0.7, 0.4), Vector3.new(0, 4.3, 0), Color3.fromRGB(62, 39, 35))
	elseif id == "boneca" then
		addPart(model, "Dress", Vector3.new(2.2, 0.9, 1.4), Vector3.new(0, 0.45, 0), Color3.fromRGB(244, 143, 177))
		addPart(model, "Bow", Vector3.new(0.9, 0.35, 0.25), Vector3.new(0, 3.75, -0.6), Color3.fromRGB(233, 30, 99))
	elseif id == "trippi" then
		addPart(model, "Fin", Vector3.new(0.25, 1.0, 0.9), Vector3.new(0, 3.9, 0), Color3.fromRGB(255, 138, 101))
		addPart(model, "Tail", Vector3.new(0.5, 1.1, 0.25), Vector3.new(0, 1.2, 0.75), Color3.fromRGB(255, 138, 101))
	elseif id == "lirili" then
		addPart(model, "SpikeLeft", Vector3.new(0.3, 0.8, 0.3), Vector3.new(-1.1, 2.2, 0), Color3.fromRGB(46, 125, 50))
		addPart(model, "SpikeRight", Vector3.new(0.3, 0.8, 0.3), Vector3.new(1.1, 2.2, 0), Color3.fromRGB(46, 125, 50))
		addPart(model, "Flower", Vector3.new(0.7, 0.35, 0.7), Vector3.new(0, 3.85, 0), Color3.fromRGB(255, 64, 129))
	elseif id == "frigo" then
		addPart(model, "FridgeDoor", Vector3.new(1.7, 1.9, 0.15), Vector3.new(0, 1.6, -0.65), Color3.fromRGB(207, 216, 220))
		addPart(model, "Handle", Vector3.new(0.18, 1.0, 0.18), Vector3.new(0.6, 1.7, -0.75), Color3.fromRGB(96, 125, 139))
	elseif id == "chimpanzini" then
		addPart(model, "Banana", Vector3.new(0.45, 1.6, 0.45), Vector3.new(0.9, 2.6, -0.3), Color3.fromRGB(255, 235, 59))
		addPart(model, "EarLeft", Vector3.new(0.4, 0.6, 0.3), Vector3.new(-0.85, 3.1, 0), Color3.fromRGB(141, 110, 99))
		addPart(model, "EarRight", Vector3.new(0.4, 0.6, 0.3), Vector3.new(0.85, 3.1, 0), Color3.fromRGB(141, 110, 99))
	elseif id == "brrbrr" then
		addPart(model, "IceShard", Vector3.new(0.5, 1.2, 0.5), Vector3.new(0, 4.1, 0), Color3.fromRGB(179, 229, 252), Enum.Material.Ice)
		addPart(model, "IceLeft", Vector3.new(0.35, 0.7, 0.35), Vector3.new(-1.05, 1.4, 0), Color3.fromRGB(179, 229, 252), Enum.Material.Ice)
		addPart(model, "IceRight", Vector3.new(0.35, 0.7, 0.35), Vector3.new(1.05, 1.4, 0), Color3.fromRGB(179, 229, 252), Enum.Material.Ice)
	elseif id == "ballerina" then
		addPart(model, "Tutu", Vector3.new(2.6, 0.35, 2.0), Vector3.new(0, 0.85, 0), Color3.fromRGB(248, 187, 208))
		addPart(model, "Bun", Vector3.new(0.6, 0.6, 0.6), Vector3.new(0, 3.95, 0), Color3.fromRGB(93, 64, 55), Enum.PartType.Ball)
	elseif id == "cappuccino" then
		addPart(model, "Cup", Vector3.new(1.2, 0.9, 1.2), Vector3.new(0, 4.0, 0), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		addPart(model, "Steam", Vector3.new(0.3, 0.8, 0.3), Vector3.new(0.3, 4.8, 0), Color3.fromRGB(224, 224, 224))
	elseif id == "orangutini" then
		addPart(model, "PineappleTop", Vector3.new(1.0, 0.7, 1.0), Vector3.new(0, 3.95, 0), Color3.fromRGB(46, 125, 50))
		addPart(model, "PineappleSpike", Vector3.new(0.25, 0.8, 0.25), Vector3.new(0, 4.5, 0), Color3.fromRGB(27, 94, 32))
	elseif id == "lavaca" then
		addPart(model, "Ring", Vector3.new(2.8, 0.15, 2.8), Vector3.new(0, 3.1, 0), Color3.fromRGB(255, 213, 79), Enum.Material.Neon)
		addPart(model, "HornLeft", Vector3.new(0.3, 0.8, 0.3), Vector3.new(-0.7, 3.8, 0), Color3.fromRGB(255, 255, 255))
		addPart(model, "HornRight", Vector3.new(0.3, 0.8, 0.3), Vector3.new(0.7, 3.8, 0), Color3.fromRGB(255, 255, 255))
	elseif id == "tralalero" then
		addPart(model, "SharkFin", Vector3.new(0.25, 1.2, 1.0), Vector3.new(0, 4.0, 0), Color3.fromRGB(21, 101, 192))
		addPart(model, "Teeth", Vector3.new(1.1, 0.3, 0.2), Vector3.new(0, 2.75, -0.62), Color3.fromRGB(255, 255, 255))
	elseif id == "bombardiro" then
		addPart(model, "Bomb", Vector3.new(0.9, 0.9, 0.9), Vector3.new(0, 4.1, 0), Color3.fromRGB(33, 33, 33), Enum.PartType.Ball)
		addPart(model, "Fuse", Vector3.new(0.15, 0.7, 0.15), Vector3.new(0, 4.8, 0), Color3.fromRGB(255, 152, 0))
		addPart(model, "Snout", Vector3.new(1.4, 0.6, 0.9), Vector3.new(0, 2.9, -0.7), Color3.fromRGB(85, 139, 47))
	elseif id == "giraffa" then
		addPart(model, "Neck", Vector3.new(0.8, 1.6, 0.8), Vector3.new(0, 4.4, 0), color)
		addPart(model, "GiraffeHead", Vector3.new(1.0, 0.8, 1.3), Vector3.new(0, 5.4, -0.2), color)
		addPart(model, "OssiconeLeft", Vector3.new(0.25, 0.6, 0.25), Vector3.new(-0.35, 5.95, -0.2), Color3.fromRGB(93, 64, 55))
		addPart(model, "OssiconeRight", Vector3.new(0.25, 0.6, 0.25), Vector3.new(0.35, 5.95, -0.2), Color3.fromRGB(93, 64, 55))
	elseif id == "bananita" then
		addPart(model, "DolphinFin", Vector3.new(0.25, 1.0, 0.9), Vector3.new(0, 3.95, 0), Color3.fromRGB(244, 143, 177))
		addPart(model, "DolphinTail", Vector3.new(0.9, 0.5, 0.4), Vector3.new(0, 0.6, 0.8), Color3.fromRGB(244, 143, 177))
		addPart(model, "BananaPeel", Vector3.new(0.4, 1.4, 0.4), Vector3.new(-0.95, 2.4, 0.2), Color3.fromRGB(255, 235, 59))
	elseif id == "graipuss" then
		addPart(model, "Dome", Vector3.new(1.8, 1.0, 1.8), Vector3.new(0, 4.0, 0), Color3.fromRGB(206, 147, 216), Enum.PartType.Ball)
		addPart(model, "TentacleLeft", Vector3.new(0.25, 1.3, 0.25), Vector3.new(-0.7, 0.7, 0), Color3.fromRGB(186, 104, 200))
		addPart(model, "TentacleRight", Vector3.new(0.25, 1.3, 0.25), Vector3.new(0.7, 0.7, 0), Color3.fromRGB(186, 104, 200))
		addPart(model, "TentacleMid", Vector3.new(0.25, 1.5, 0.25), Vector3.new(0, 0.6, 0), Color3.fromRGB(186, 104, 200))
	end
end

-- A glowing trim above the head for mutated characters, so a rare spawn
-- is visible from across the island at a glance.
local function addMutationTrim(model, mutationId)
	if mutationId == "normal" then
		return
	end
	local trimColor = BrainrotData.MutationColors[mutationId] or Color3.fromRGB(255, 255, 255)
	local crown = addPart(model, "MutationTrim", Vector3.new(1.9, 0.3, 1.4), Vector3.new(0, 3.65, 0), trimColor, Enum.Material.Neon)
	crown.Transparency = 0.15
	local light = Instance.new("PointLight")
	light.Name = "MutationLight"
	light.Color = trimColor
	light.Range = 6
	light.Brightness = 1.5
	light.Parent = crown
end

-- The name label every character wears: name, tier, and income per second.
local function addLabel(model, entry, mutationId)
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameLabel"
	gui.Size = UDim2.new(0, 160, 0, 56)
	gui.StudsOffset = Vector3.new(0, 4.6, 0)
	gui.AlwaysOnTop = true
	gui.Parent = model
	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.2
	local income = BrainrotData.characterIncome(entry, mutationId)
	local tag = ""
	if mutationId ~= "normal" then
		tag = " [" .. string.upper(mutationId) .. "]"
	end
	label.Text = entry.name .. tag .. "\n" .. entry.tier .. " - $" .. tostring(income) .. "/s"
	label.Parent = gui
end

-- Build one character model. entry is a row from BrainrotData.Characters,
-- mutationId is "normal", "gold", "diamond" or "rainbow". The model is
-- parented nowhere; the caller places it.
function BrainrotModels.build(entry, mutationId)
	local model = Instance.new("Model")
	model.Name = entry.id
	local body = addPart(model, "Body", Vector3.new(2.0, 2.4, 1.2), Vector3.new(0, 1.2, 0), entry.color)
	local head = addPart(model, "Head", Vector3.new(1.4, 1.2, 1.2), Vector3.new(0, 3.0, 0), entry.color)
	addEyes(model, 3.1)
	addFeature(model, entry.id, entry.color)
	addMutationTrim(model, mutationId)
	addLabel(model, entry, mutationId)
	model.PrimaryPart = body
	return model
end

-- A golden-event character: the same model, but wrapped in gold — a gold
-- crown, a gold light, and a gold label, so it screams "rare" from afar.
function BrainrotModels.buildGolden(entry)
	local model = BrainrotModels.build(entry, "gold")
	model.Name = entry.id .. "_golden"
	local crown = addPart(model, "GoldenCrown", Vector3.new(2.1, 0.4, 1.5), Vector3.new(0, 3.7, 0), Color3.fromRGB(255, 215, 0), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Name = "GoldenLight"
	light.Color = Color3.fromRGB(255, 215, 0)
	light.Range = 10
	light.Brightness = 2
	light.Parent = crown
	return model
end

return BrainrotModels
