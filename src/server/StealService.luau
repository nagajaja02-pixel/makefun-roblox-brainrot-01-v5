-- StealService: the steal in steal-a-brainrot. Clicking a character on
-- someone else's stand — while their shield is down — picks it up and
-- welds it in front of you. Walk it home and click your own base platform
-- to place it on a free stand: the steal succeeds. If you die, leave, or
-- have no free stand, the character goes straight back to its owner's
-- stand. Clicking your own character sells it for half price instead.

local Players = game:GetService("Players")
local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)

local StealService = {}

-- model -> { owner, slot, entry, mutationId } for every placed character.
local placed = {}
-- player -> { model, victim, slot, entry, mutationId } while carrying.
local carrying = {}

local function setModelAnchored(model, anchored)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = anchored
			part.CanCollide = false
		end
	end
end

function StealService.init(ctx)
	local world = ctx.world
	local events = ctx.events
	local remotes = ctx.remotes
	local baseService = ctx.services.BaseService
	local shieldService = ctx.services.ShieldService

	local function returnToOwner(record)
		if not record then
			return
		end
		local victim = record.owner
		local baseIndex = baseService.getBaseIndex(victim)
		if baseIndex then
			local base = world.bases[baseIndex]
			local padPos = base.pads[record.slot]
			if padPos and record.model and record.model.Parent then
				setModelAnchored(record.model, true)
				record.model.Parent = base.model
				record.model:PivotTo(CFrame.new(padPos + Vector3.new(0, 1.5, 0)))
				return
			end
		end
		if record.model then
			record.model:Destroy()
		end
	end

	local function stopCarrying(player, restore)
		local record = carrying[player]
		if not record then
			return
		end
		carrying[player] = nil
		local flag = player:FindFirstChild("Carrying")
		if flag then
			flag.Value = false
		end
		local character = player.Character
		if character then
			local weld = character:FindFirstChild("CarryWeld")
			if weld then
				weld:Destroy()
			end
		end
		if restore then
			returnToOwner(record)
		end
	end

	-- When a character lands on a stand, give it a click handler: the
	-- owner sells it, anyone else tries to steal it.
	events.CharacterPlaced.Event:Connect(function(player, slot, model, entry, mutationId)
		placed[model] = { owner = player, slot = slot, entry = entry, mutationId = mutationId }
		local detector = Instance.new("ClickDetector")
		detector.MaxActivationDistance = 32
		detector.Parent = model
		detector.MouseClick:Connect(function(clicker)
			local info = placed[model]
			if not info then
				return
			end
			if clicker == info.owner then
				events.SellRequested:Fire(clicker, info.slot)
				placed[model] = nil
				return
			end
			if carrying[clicker] then
				remotes.Notify:FireClient(clicker, "You are already carrying a brainrot!")
				return
			end
			if shieldService.isShieldActive(info.owner) then
				remotes.Notify:FireClient(clicker, info.owner.Name .. "'s shield is up! Come back later.")
				return
			end
			-- Pick it up: unanchor, weld it in front of the carrier.
			local character = clicker.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not root then
				return
			end
			setModelAnchored(model, false)
			local weld = Instance.new("Weld")
			weld.Name = "CarryWeld"
			weld.Part0 = root
			weld.Part1 = model.PrimaryPart
			weld.C0 = CFrame.new(0, 0, -2.5)
			weld.Parent = character
			model.Parent = character
			placed[model] = nil
			carrying[clicker] = { model = model, victim = info.owner, slot = info.slot, entry = info.entry, mutationId = info.mutationId }
			local flag = clicker:FindFirstChild("Carrying")
			if not flag then
				flag = Instance.new("BoolValue")
				flag.Name = "Carrying"
				flag.Parent = clicker
			end
			flag.Value = true
			remotes.Notify:FireClient(clicker, "You stole " .. info.entry.name .. "! Carry it home to your base.")
			remotes.Notify:FireClient(info.owner, clicker.Name .. " is stealing your " .. info.entry.name .. "!")
		end)
	end)

	-- Clicking your own base platform while carrying places the stolen
	-- character on your first free stand. No free stand: it goes back.
	for _, base in ipairs(world.bases) do
		local platform = base.model:FindFirstChild("Platform")
		if platform then
			local detector = Instance.new("ClickDetector")
			detector.MaxActivationDistance = 40
			detector.Parent = platform
			detector.MouseClick:Connect(function(clicker)
				local record = carrying[clicker]
				if not record then
					return
				end
				local myIndex = baseService.getBaseIndex(clicker)
				if myIndex ~= base.index then
					remotes.Notify:FireClient(clicker, "That is not your base!")
					return
				end
				if not baseService.hasFreeStand(clicker) then
					remotes.Notify:FireClient(clicker, "No free stand! The brainrot escapes back.")
					stopCarrying(clicker, true)
					return
				end
				-- Place it on the first free stand of the carrier's base.
				local count = baseService.getStandCount(clicker)
				local slot = nil
				for i = 1, count do
					if baseService.getSlot(clicker, i) == nil then
						slot = i
						break
					end
				end
				if slot == nil then
					stopCarrying(clicker, true)
					return
				end
				local model = record.model
				local character = clicker.Character
				if character then
					local weld = character:FindFirstChild("CarryWeld")
					if weld then
						weld:Destroy()
					end
				end
				local flag = clicker:FindFirstChild("Carrying")
				if flag then
					flag.Value = false
				end
				carrying[clicker] = nil
				local padPos = base.pads[slot]
				setModelAnchored(model, true)
				model.Parent = base.model
				model:PivotTo(CFrame.new(padPos + Vector3.new(0, 1.5, 0)))
				events.CharacterPlaced:Fire(clicker, slot, model, record.entry, record.mutationId)
				remotes.Notify:FireClient(clicker, "Stolen! " .. record.entry.name .. " is yours now.")
				remotes.Notify:FireClient(record.victim, clicker.Name .. " stole your " .. record.entry.name .. "!")
			end)
		end
	end

	-- If the carrier dies or leaves, the brainrot goes home.
	Players.PlayerRemoving:Connect(function(player)
		stopCarrying(player, true)
	end)
	local function watchCharacter(player)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid", 5)
			if humanoid then
				humanoid.Died:Connect(function()
					stopCarrying(player, true)
				end)
			end
		end)
	end
	Players.PlayerAdded:Connect(watchCharacter)
	for _, player in ipairs(Players:GetPlayers()) do
		watchCharacter(player)
	end

	-- The menu's sell grid: selling a stand by number. The server checks
	-- the slot really holds one of the caller's own characters before it
	-- pays out, so a client cannot sell someone else's brainrot.
	remotes.SellCharacter.OnServerEvent:Connect(function(player, slot)
		if typeof(slot) ~= "number" then
			return
		end
		for model, info in pairs(placed) do
			if info.owner == player and info.slot == slot then
				events.SellRequested:Fire(player, slot)
				placed[model] = nil
				return
			end
		end
		remotes.Notify:FireClient(player, "Nothing to sell on stand " .. tostring(slot) .. ".")
	end)

	-- A sold character is no longer tracked as placed.
	events.CharacterRemoved.Event:Connect(function(_player, _slot)
		-- The model was destroyed by the seller, so nothing to clean up
		-- here; the placed map is cleared by the click handler.
	end)
end

return StealService
