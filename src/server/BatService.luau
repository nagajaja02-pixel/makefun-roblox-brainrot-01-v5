-- BatService: the free baseball bat every player gets for raid defense.
--
-- Every player spawns with a wooden baseball bat in their Backpack. When a
-- rival is raiding your safehouse, equip the bat and click to swing. A swing
-- has a short cooldown and only reaches a short distance in front of you, so
-- you have to get close. A player caught by the swing is shoved hard away
-- from you. If that player is carrying a stolen brainrot, the hit knocks the
-- brainrot out of their hands and the raid fails: the character drops to the
-- floor and the steal system is told the carry was interrupted.
--
-- The service talks to the steal system through the server bus, not by
-- requiring it: it watches the CharacterRemoved / CharacterPlaced bus events
-- to track who is carrying, and it fires a CarryInterrupted bus event when a
-- bat hit breaks a carry. It also checks the target's character directly for
-- a carried brainrot model, so the drop works even if the bus tracking and
-- the steal system disagree about the carry state.

local Players = game:GetService("Players")
local StarterPack = game:GetService("StarterPack")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local BatService = {}

-- Tuning. Kept small and fair: a short cooldown, a short reach, a strong
-- shove, and a carry is always broken when the swing connects.
local SWING_COOLDOWN = 1.0
local HIT_RANGE = 8
local FRONT_DOT = 0.5
local KNOCKBACK_SPEED = 55
local KNOCKBACK_UP = 22
local KNOCKBACK_TIME = 0.25
local TRAIL_TIME = 0.35
local SWING_SOUND_ID = "rbxassetid://13107247" -- a whoosh; swap for any whoosh asset id

local TOOL_NAME = "Baseball Bat"

local lastSwing = {}
local carryingFlag = {}

local ctx = nil

local function findPlayerArg(...)
	for _, value in ipairs({ ... }) do
		if typeof(value) == "Instance" and value:IsA("Player") then
			return value
		end
	end
	return nil
end

local function getRootPart(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

-- findCarriedModel: a carried brainrot is a Model attached to the player's
-- character. Body parts are BaseParts and accessories are Accessory
-- instances, so a Model child of the character can only be a carried
-- character. Returns nil when the player holds nothing.
local function findCarriedModel(player)
	local character = player.Character
	if not character then
		return nil
	end
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Model") then
			return child
		end
	end
	return nil
end

-- isCarrying: true when the player is currently carrying a stolen character.
-- Two signals, either one is enough: the bus-tracked carry flag, or a
-- carried brainrot model physically attached to the player's character.
local function isCarrying(player)
	if carryingFlag[player] then
		return true
	end
	return findCarriedModel(player) ~= nil
end

-- dropCarried: make a carrying player drop the brainrot they hold. The model
-- is moved out of the character into the world at the player's feet, its
-- parts are unanchored and solid so it falls to the floor instead of
-- floating, and the steal system is told through the bus that the carry was
-- interrupted so it can clear its own carry state and handle the character
-- instead of letting the raider keep it.
local function dropCarried(player)
	local model = findCarriedModel(player)
	if model then
		local root = getRootPart(player)
		local dropAt = root and root.Position or Vector3.new(0, 5, 0)
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = true
			end
		end
		model.Parent = Workspace
		pcall(function()
			model:PivotTo(CFrame.new(dropAt + Vector3.new(0, 1.5, 0)))
		end)
	end
	carryingFlag[player] = nil
	if ctx and ctx.events and ctx.events.CarryInterrupted then
		ctx.events.CarryInterrupted:Fire(player, model)
	end
end

-- knockback: shove a player hard away from the swinger, with a small pop up.
-- A short-lived BodyVelocity does the push, then Debris removes it.
local function knockback(target, fromPosition)
	local root = getRootPart(target)
	if not root then
		return
	end
	local away = root.Position - fromPosition
	away = Vector3.new(away.X, 0, away.Z)
	if away.Magnitude < 0.01 then
		away = Vector3.new(0, 0, 1)
	end
	away = away.Unit
	local push = Instance.new("BodyVelocity")
	push.Name = "BatKnockback"
	push.MaxForce = Vector3.new(1, 1, 1) * 100000
	push.Velocity = away * KNOCKBACK_SPEED + Vector3.new(0, KNOCKBACK_UP, 0)
	push.Parent = root
	Debris:AddItem(push, KNOCKBACK_TIME)
end

-- findTarget: the nearest other player inside the swing's reach and in front
-- of the swinger. Returns nil when nobody is close enough or in front, so
-- the bat can never hit the swinger themselves or a far-away player.
local function findTarget(swinger)
	local root = getRootPart(swinger)
	if not root then
		return nil
	end
	local origin = root.Position
	local look = root.CFrame.LookVector
	look = Vector3.new(look.X, 0, look.Z)
	if look.Magnitude < 0.01 then
		return nil
	end
	look = look.Unit

	local best = nil
	local bestDist = HIT_RANGE + 1
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= swinger then
			local otherRoot = getRootPart(other)
			if otherRoot then
				local toOther = otherRoot.Position - origin
				local dist = toOther.Magnitude
				if dist <= HIT_RANGE and dist < bestDist then
					local dir = Vector3.new(toOther.X, 0, toOther.Z)
					if dir.Magnitude > 0.01 then
						dir = dir.Unit
						if dir:Dot(look) >= FRONT_DOT then
							best = other
							bestDist = dist
						end
					end
				end
			end
		end
	end
	return best
end

-- makeBatTool: build one bat Tool. The Handle is a brown wooden bat with a
-- wider barrel welded to its top end. A Trail along the handle and a whoosh
-- sound give the swing its feedback.
local function makeBatTool()
	local tool = Instance.new("Tool")
	tool.Name = TOOL_NAME
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ToolTip = "Swing to knock back raiders — a hit makes a thief drop the brainrot they are carrying!"

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.45, 2.2, 0.45)
	handle.Color = Color3.fromRGB(139, 90, 43)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.CanQuery = false
	handle.Parent = tool

	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Size = Vector3.new(0.65, 0.9, 0.65)
	barrel.Color = Color3.fromRGB(160, 105, 50)
	barrel.Material = Enum.Material.Wood
	barrel.CanCollide = false
	barrel.CanQuery = false
	local barrelWeld = Instance.new("Weld")
	barrelWeld.Part0 = handle
	barrelWeld.Part1 = barrel
	barrelWeld.C0 = CFrame.new(0, 1.35, 0)
	barrelWeld.Parent = handle
	barrel.Parent = tool

	-- Trail along the bat, enabled only during a swing.
	local attachTop = Instance.new("Attachment")
	attachTop.Name = "TrailTop"
	attachTop.Position = Vector3.new(0, 1.6, 0)
	attachTop.Parent = handle
	local attachBottom = Instance.new("Attachment")
	attachBottom.Name = "TrailBottom"
	attachBottom.Position = Vector3.new(0, -1, 0)
	attachBottom.Parent = handle
	local trail = Instance.new("Trail")
	trail.Name = "SwingTrail"
	trail.Attachment0 = attachTop
	trail.Attachment1 = attachBottom
	trail.Lifetime = 0.3
	trail.MinLength = 0.1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Enabled = false
	trail.Parent = handle

	local sound = Instance.new("Sound")
	sound.Name = "SwingSound"
	sound.SoundId = SWING_SOUND_ID
	sound.Volume = 0.6
	sound.Parent = handle

	return tool
end

-- playSwingEffects: the whoosh and a brief trail streak.
local function playSwingEffects(tool)
	local handle = tool:FindFirstChild("Handle")
	if not handle then
		return
	end
	local sound = handle:FindFirstChild("SwingSound")
	if sound then
		sound:Play()
	end
	local trail = handle:FindFirstChild("SwingTrail")
	if trail then
		trail.Enabled = true
		task.delay(TRAIL_TIME, function()
			pcall(function()
				trail.Enabled = false
			end)
		end)
	end
end

-- onSwing: a player clicked while holding the bat. Enforce the cooldown,
-- play the effects, then find and hit the nearest player in front. A hit
-- always knocks the target back; if the target is carrying a stolen
-- brainrot, the hit also makes them drop it and the raid fails.
local function onSwing(player, tool)
	local now = os.clock()
	local last = lastSwing[player]
	if last and now - last < SWING_COOLDOWN then
		return
	end
	lastSwing[player] = now

	playSwingEffects(tool)

	local target = findTarget(player)
	if not target then
		return
	end

	local root = getRootPart(player)
	if root then
		knockback(target, root.Position)
	end

	local wasCarrying = isCarrying(target)
	if wasCarrying then
		dropCarried(target)
	end

	if ctx and ctx.remotes and ctx.remotes.Notify then
		if wasCarrying then
			ctx.remotes.Notify:FireClient(player, "You smashed the raider and they dropped the stolen brainrot!")
			ctx.remotes.Notify:FireClient(target, "A bat smashed you — you dropped the brainrot you were carrying!")
		else
			ctx.remotes.Notify:FireClient(player, "You knocked back " .. target.DisplayName .. "!")
			ctx.remotes.Notify:FireClient(target, "You were knocked back by a baseball bat!")
		end
	end
end

local function hasBat(player)
	local backpack = player:FindFirstChild("Backpack")
	if backpack and backpack:FindFirstChild(TOOL_NAME) then
		return true
	end
	local character = player.Character
	if character and character:FindFirstChild(TOOL_NAME) then
		return true
	end
	return false
end

-- giveBat: hand one bat to a player (once). Connects its Activated event so
-- a click while equipped swings it. The connection dies with the tool.
local function giveBat(player)
	if hasBat(player) then
		return
	end
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		return
	end
	local tool = makeBatTool()
	tool.Activated:Connect(function()
		onSwing(player, tool)
	end)
	tool.Parent = backpack
end

local function hookPlayer(player)
	giveBat(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		giveBat(player)
	end)
end

function BatService.init(serviceCtx)
	ctx = serviceCtx

	-- Track who is carrying through the bus: a character leaves a stand when
	-- it is picked up (CharacterRemoved) and stops being carried when it is
	-- placed again (CharacterPlaced). The payload order is not assumed; the
	-- player is found among the event arguments.
	if ctx.events.CharacterRemoved then
		ctx.events.CharacterRemoved.Event:Connect(function(...)
			local player = findPlayerArg(...)
			if player then
				carryingFlag[player] = true
			end
		end)
	end
	if ctx.events.CharacterPlaced then
		ctx.events.CharacterPlaced.Event:Connect(function(...)
			local player = findPlayerArg(...)
			if player then
				carryingFlag[player] = nil
			end
		end)
	end

	-- A bat in StarterPack means every respawn gets one automatically.
	local starterBat = makeBatTool()
	starterBat.Parent = StarterPack

	-- Hand a bat to everyone already in the game, and to each newcomer.
	for _, player in ipairs(Players:GetPlayers()) do
		hookPlayer(player)
	end
	Players.PlayerAdded:Connect(hookPlayer)

	-- Cooldown and carry flags die with the player.
	Players.PlayerRemoving:Connect(function(player)
		lastSwing[player] = nil
		carryingFlag[player] = nil
	end)
end

return BatService
