-- BaseService: the six safehouses. Each player claims one base on join,
-- with four stands to start and room to upgrade to ten. When a purchase is
-- approved, the character is placed on the player's first free stand. When
-- a stand is bought, the player pays through MoneyService and a new pad
-- opens up. When a character leaves a stand (sold or stolen), the slot
-- frees up again.

local Players = game:GetService("Players")
local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)

local BaseService = {}

-- Per-base state: who owns it, how many stands are open, and what sits on
-- each of the ten pads (a record or nil).
local bases = {}
local playerBase = {}

local function setSignOwner(world, baseIndex, ownerName)
	local base = world.bases[baseIndex]
	if not base then
		return
	end
	local gui = base.signGui
	local ownerLabel = gui:FindFirstChild("BoardLine1")
	if ownerLabel then
		ownerLabel.Text = ownerName or "Unclaimed"
	end
end

local function freeStandCount(base)
	local free = 0
	for i = 1, base.standCount do
		if base.slots[i] == nil then
			free += 1
		end
	end
	return free
end

function BaseService.init(ctx)
	local world = ctx.world
	local events = ctx.events
	local remotes = ctx.remotes

	for i, base in ipairs(world.bases) do
		bases[i] = {
			owner = nil,
			standCount = BrainrotData.Economy.startStands,
			slots = {},
			record = base,
		}
	end

	local function assignBase(player)
		for i, base in ipairs(bases) do
			if base.owner == nil then
				base.owner = player
				playerBase[player] = i
				setSignOwner(world, i, player.Name .. "'s Base")
				return i
			end
		end
		return nil
	end

	local function releaseBase(player)
		local index = playerBase[player]
		if not index then
			return
		end
		local base = bases[index]
		for slot, record in pairs(base.slots) do
			if record and record.model then
				record.model:Destroy()
			end
			base.slots[slot] = nil
		end
		base.owner = nil
		base.standCount = BrainrotData.Economy.startStands
		playerBase[player] = nil
		setSignOwner(world, index, "Unclaimed")
	end

	Players.PlayerAdded:Connect(function(player)
		assignBase(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		releaseBase(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		assignBase(player)
	end

	-- A purchase was approved: put the character on the player's first
	-- free stand. If there is no free stand, refund the player.
	events.PurchaseApproved.Event:Connect(function(player, entry, mutationId, price, model, isGolden)
		local index = playerBase[player]
		if not index then
			events.Refund:Fire(player, price)
			events.PurchaseDenied:Fire(player, "No base assigned", model)
			return
		end
		local base = bases[index]
		local slot = nil
		for i = 1, base.standCount do
			if base.slots[i] == nil then
				slot = i
				break
			end
		end
		if slot == nil then
			events.Refund:Fire(player, price)
			events.PurchaseDenied:Fire(player, "No free stand", model)
			return
		end
		local padPos = base.record.pads[slot]
		model.Parent = base.record.model
		model:PivotTo(CFrame.new(padPos + Vector3.new(0, 1.5, 0)))
		local record = {
			entry = entry,
			mutationId = mutationId,
			model = model,
			isGolden = isGolden,
		}
		base.slots[slot] = record
		events.CharacterPlaced:Fire(player, slot, model, entry, mutationId)
	end)

	-- A character left a stand (sold or stolen): free the slot.
	events.CharacterRemoved.Event:Connect(function(player, slot)
		local index = playerBase[player]
		if not index then
			return
		end
		bases[index].slots[slot] = nil
	end)

	-- Buying a stand: charge through MoneyService, open the pad on approval.
	remotes.BuyStand.OnServerEvent:Connect(function(player)
		local index = playerBase[player]
		if not index then
			return
		end
		local base = bases[index]
		if base.standCount >= BrainrotData.Economy.maxStands then
			remotes.Notify:FireClient(player, "Your stands are already maxed out!")
			return
		end
		local cost = BrainrotData.upgradeCost(base.standCount)
		events.ChargeRequested:Fire(player, cost, "stand", { baseIndex = index })
	end)

	events.ChargeApproved.Event:Connect(function(player, purpose, payload)
		if purpose ~= "stand" then
			return
		end
		local index = payload.baseIndex or playerBase[player]
		if not index then
			return
		end
		local base = bases[index]
		if base.standCount < BrainrotData.Economy.maxStands then
			base.standCount += 1
			remotes.Notify:FireClient(player, "Stand upgraded! You now have " .. tostring(base.standCount) .. " stands.")
		end
	end)
end

-- Read access for other services: the base a player owns, and whether it
-- has a free stand.
function BaseService.getBaseIndex(player)
	return playerBase[player]
end

function BaseService.getStandCount(player)
	local index = playerBase[player]
	if not index then
		return 0
	end
	return bases[index].standCount
end

function BaseService.getSlot(player, slot)
	local index = playerBase[player]
	if not index then
		return nil
	end
	return bases[index].slots[slot]
end

function BaseService.hasFreeStand(player)
	local index = playerBase[player]
	if not index then
		return false
	end
	return freeStandCount(bases[index]) > 0
end

return BaseService
