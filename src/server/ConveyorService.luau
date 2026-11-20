-- ConveyorService: the belt that supplies the whole game. A new character
-- rolls out every few seconds, rides the belt from one end to the other,
-- and despawns if nobody buys it. Clicking a character starts a purchase:
-- the model is reserved, MoneyService checks the cash, and BaseService
-- places it on a free stand. Every few minutes a Golden Brainrot appears —
-- five times the price and income of its tier, announced to everyone.

local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)
local BrainrotModels = require(script.Parent.BrainrotModels)

local ConveyorService = {}

-- One belt item: the model, its character entry, its mutation, its price,
-- whether it is a golden-event spawn, and whether a purchase is pending.
local active = {}

local function placeOnBelt(model, x, y)
	model:PivotTo(CFrame.new(x, y, 0))
end

function ConveyorService.init(ctx)
	local world = ctx.world
	local events = ctx.events
	local remotes = ctx.remotes
	local beltY = world.conveyor.beltY
	local reserved = {}

	local function spawnOne(isGolden)
		local entry = BrainrotData.pickRandomCharacter()
		local mutationId = BrainrotData.rollMutation()
		local model
		local price = entry.price
		local income = entry.income
		if isGolden then
			model = BrainrotModels.buildGolden(entry)
			price = entry.price * BrainrotData.Golden.mult
			income = entry.income * BrainrotData.Golden.mult
		else
			model = BrainrotModels.build(entry, mutationId)
		end
		model.Parent = world.folder
		placeOnBelt(model, BrainrotData.Conveyor.minX, beltY)
		local record = {
			model = model,
			entry = entry,
			mutationId = mutationId,
			price = price,
			income = income,
			isGolden = isGolden,
		}
		table.insert(active, record)
		local detector = Instance.new("ClickDetector")
		detector.MaxActivationDistance = 32
		detector.Parent = model
		detector.MouseClick:Connect(function(player)
			if reserved[model] then
				return
			end
			reserved[model] = true
			events.PurchaseRequested:Fire(player, entry, mutationId, price, model, isGolden)
		end)
		if isGolden then
			remotes.GoldenAnnounce:FireAllClients(entry.name, price)
		end
		return record
	end

	-- Public trigger so the admin service can spawn a golden on demand.
	-- The scheduled golden loop below keeps using spawnOne directly.
	ConveyorService.spawnGolden = function()
		spawnOne(true)
	end

	-- A single movement loop drives every item on the belt, so the belt
	-- never needs one thread per character.
	task.spawn(function()
		while true do
			task.wait(0.1)
			local dt = 0.1
			local step = BrainrotData.Conveyor.speed * dt
			for i = #active, 1, -1 do
				local record = active[i]
				local model = record.model
				if not model.Parent then
					table.remove(active, i)
				else
					local pos = model:GetPivot().Position
					local nextX = pos.X + step
					if nextX >= BrainrotData.Conveyor.maxX then
						model:Destroy()
						table.remove(active, i)
					else
						placeOnBelt(model, nextX, beltY)
					end
				end
			end
		end
	end)

	-- Spawn loop: a fresh character every few seconds.
	task.spawn(function()
		while true do
			task.wait(BrainrotData.Conveyor.spawnInterval)
			spawnOne(false)
		end
	end)

	-- Golden Brainrot event: a rare golden character every few minutes.
	task.spawn(function()
		while true do
			task.wait(BrainrotData.Golden.interval)
			spawnOne(true)
		end
	end)

	-- When a purchase is approved, the model leaves the belt for good.
	events.PurchaseApproved.Event:Connect(function(_player, _entry, _mutationId, _price, model, _isGolden)
		reserved[model] = nil
		for i = #active, 1, -1 do
			if active[i].model == model then
				table.remove(active, i)
				break
			end
		end
	end)

	-- When a purchase is denied, the model goes back on sale on the belt.
	events.PurchaseDenied.Event:Connect(function(_player, _reason, model)
		if model then
			reserved[model] = nil
		end
	end)
end

return ConveyorService
