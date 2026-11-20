-- MoneyService: every dollar in the game. It owns the leaderstats (Cash,
-- Income, Rebirths), pays out one second of stand income every second,
-- charges for purchases and stand upgrades, pays for sales, runs rebirth,
-- and keeps the top-three leaderboard fresh. Rebirth counts persist in the
-- BlitzRebirthsV1 DataStore, so a returning player keeps their prestige.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)

local MoneyService = {}

local rebirthStore = nil
local rebirths = {}

local function getStore()
	if rebirthStore ~= nil then
		return rebirthStore
	end
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(BrainrotData.DataStoreName)
	end)
	if ok then
		rebirthStore = store
	end
	return rebirthStore
end

function MoneyService.init(ctx)
	local world = ctx.world
	local events = ctx.events
	local remotes = ctx.remotes
	local baseService = ctx.services.BaseService

	local function setupPlayer(player)
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
		local cash = Instance.new("IntValue")
		cash.Name = "Cash"
		cash.Value = BrainrotData.Economy.startCash
		cash.Parent = leaderstats
		local income = Instance.new("IntValue")
		income.Name = "Income"
		income.Value = 0
		income.Parent = leaderstats
		local rebirthCount = Instance.new("IntValue")
		rebirthCount.Name = "Rebirths"
		rebirthCount.Value = 0
		rebirthCount.Parent = leaderstats
		rebirths[player] = 0
		local store = getStore()
		if store then
			local ok, saved = pcall(function()
				return store:GetAsync(tostring(player.UserId))
			end)
			if ok and typeof(saved) == "number" then
				rebirths[player] = saved
				rebirthCount.Value = saved
			end
		end
	end

	local function savePlayer(player)
		local store = getStore()
		if store and rebirths[player] ~= nil then
			pcall(function()
				store:SetAsync(tostring(player.UserId), rebirths[player])
			end)
		end
	end

	local function cashValue(player)
		local stats = player:FindFirstChild("leaderstats")
		if not stats then
			return 0
		end
		local cash = stats:FindFirstChild("Cash")
		return cash and cash.Value or 0
	end

	local function setCash(player, amount)
		local stats = player:FindFirstChild("leaderstats")
		if not stats then
			return
		end
		local cash = stats:FindFirstChild("Cash")
		if cash then
			cash.Value = math.max(0, math.floor(amount))
		end
	end

	local function incomePerSecond(player)
		local total = 0
		local count = baseService.getStandCount(player)
		for slot = 1, count do
			local record = baseService.getSlot(player, slot)
			if record and record.entry then
				total += BrainrotData.characterIncome(record.entry, record.mutationId)
			end
		end
		return total * BrainrotData.incomeMultiplier(rebirths[player] or 0)
	end

	Players.PlayerAdded:Connect(setupPlayer)
	Players.PlayerRemoving:Connect(function(player)
		savePlayer(player)
		rebirths[player] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	-- Income loop: every second, every placed character earns its income.
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local perSecond = incomePerSecond(player)
				local stats = player:FindFirstChild("leaderstats")
				if stats then
					local incomeValue = stats:FindFirstChild("Income")
					if incomeValue then
						incomeValue.Value = math.floor(perSecond)
					end
				end
				if perSecond > 0 then
					setCash(player, cashValue(player) + perSecond)
				end
			end
		end
	end)

	-- A conveyor purchase: charge the cash, then let BaseService place it.
	events.PurchaseRequested.Event:Connect(function(player, entry, mutationId, price, model, isGolden)
		if cashValue(player) >= price then
			setCash(player, cashValue(player) - price)
			events.PurchaseApproved:Fire(player, entry, mutationId, price, model, isGolden)
		else
			events.PurchaseDenied:Fire(player, "Not enough cash", model)
			remotes.Notify:FireClient(player, "Not enough cash for " .. entry.name .. "!")
		end
	end)

	-- Refunds (for example when a purchase was approved but no stand was free).
	events.Refund.Event:Connect(function(player, amount)
		setCash(player, cashValue(player) + amount)
	end)

	-- Generic charges (stand upgrades): deduct on approval, deny otherwise.
	events.ChargeRequested.Event:Connect(function(player, amount, purpose, payload)
		if cashValue(player) >= amount then
			setCash(player, cashValue(player) - amount)
			events.ChargeApproved:Fire(player, purpose, payload)
		else
			events.ChargeDenied:Fire(player, purpose, { reason = "Not enough cash" })
			remotes.Notify:FireClient(player, "Not enough cash!")
		end
	end)

	-- Selling a character from one of your own stands: half the buy price.
	events.SellRequested.Event:Connect(function(player, slot)
		local record = baseService.getSlot(player, slot)
		if not record or not record.entry then
			return
		end
		local payout = math.floor(record.entry.price * BrainrotData.Economy.sellFraction)
		setCash(player, cashValue(player) + payout)
		if record.model then
			record.model:Destroy()
		end
		events.CharacterRemoved:Fire(player, slot)
		remotes.Notify:FireClient(player, "Sold " .. record.entry.name .. " for $" .. tostring(payout) .. ".")
	end)

	-- Rebirth: pay the price, gain a permanent +50% income (plus milestone
	-- bonuses), and start the cash pile over.
	remotes.Rebirth.OnServerEvent:Connect(function(player)
		local count = rebirths[player] or 0
		local cost = BrainrotData.rebirthCost(count)
		if cashValue(player) < cost then
			remotes.Notify:FireClient(player, "Rebirth costs $" .. tostring(cost) .. ".")
			return
		end
		setCash(player, BrainrotData.Economy.startCash)
		rebirths[player] = count + 1
		local stats = player:FindFirstChild("leaderstats")
		if stats then
			local rebirthValue = stats:FindFirstChild("Rebirths")
			if rebirthValue then
				rebirthValue.Value = count + 1
			end
		end
		savePlayer(player)
		local milestone = BrainrotData.milestoneBonus(count + 1)
		local message = "Rebirth " .. tostring(count + 1) .. "! Income +" .. tostring(math.floor(BrainrotData.incomeMultiplier(count + 1) * 100 - 100)) .. "%."
		if milestone > 0 then
			message ..= " Milestone bonus active!"
		end
		remotes.Notify:FireClient(player, message)
	end)

	-- Leaderboard: the three richest players, refreshed every ten seconds
	-- on the board in the middle of the island and on every client.
	local function refreshLeaderboard()
		local ranked = {}
		for _, player in ipairs(Players:GetPlayers()) do
			table.insert(ranked, { name = player.Name, cash = cashValue(player) })
		end
		table.sort(ranked, function(a, b)
			return a.cash > b.cash
		end)
		local top = {}
		for i = 1, 3 do
			if ranked[i] then
				top[i] = ranked[i]
			else
				top[i] = { name = "---", cash = 0 }
			end
		end
		local gui = world.boardGui
		for i = 1, 3 do
			local line = gui:FindFirstChild("BoardLine" .. tostring(i))
			if line then
				line.Text = tostring(i) .. ". " .. top[i].name .. " - $" .. tostring(top[i].cash)
			end
		end
		remotes.TopThree:FireAllClients(top)
	end

	task.spawn(function()
		while true do
			task.wait(10)
			refreshLeaderboard()
		end
	end)
	refreshLeaderboard()
end

return MoneyService
