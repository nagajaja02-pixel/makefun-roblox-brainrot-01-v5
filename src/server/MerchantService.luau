-- MerchantService: the travelling merchant by the dock. He sells three
-- characters at a time, at one and a quarter times their normal price, and
-- his stock rotates every ninety seconds — so a character you want may be
-- gone by the time you save up for it. Buying from him charges through
-- MoneyService and places the character on your first free stand, exactly
-- like a conveyor purchase.

local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)
local BrainrotModels = require(script.Parent.BrainrotModels)

local MerchantService = {}

local STOCK_SIZE = 3
local STOCK_INTERVAL = 90
local PRICE_MULT = 1.25

function MerchantService.init(ctx)
	local world = ctx.world
	local events = ctx.events
	local remotes = ctx.remotes

	local spot = world.merchantSpot
	local merchant = Instance.new("Model")
	merchant.Name = "Merchant"
	merchant.Parent = world.folder
	local function addPart(name, size, pos, color, material, shape)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Position = pos
		part.Color = color
		part.Material = material or Enum.Material.SmoothPlastic
		part.Shape = shape or Enum.PartType.Block
		part.Anchored = true
		part.CanCollide = false
		part.Parent = merchant
		return part
	end
	addPart("Body", Vector3.new(2.2, 2.6, 1.4), Vector3.new(spot.X, 1.3, spot.Z), Color3.fromRGB(121, 85, 72))
	addPart("Head", Vector3.new(1.5, 1.3, 1.3), Vector3.new(spot.X, 3.2, spot.Z), Color3.fromRGB(255, 205, 180))
	addPart("Apron", Vector3.new(1.8, 1.8, 0.3), Vector3.new(spot.X, 1.5, spot.Z - 0.8), Color3.fromRGB(255, 255, 255))
	addPart("Hat", Vector3.new(2.0, 0.5, 2.0), Vector3.new(spot.X, 4.1, spot.Z), Color3.fromRGB(255, 213, 79))
	local gui = Instance.new("BillboardGui")
	gui.Name = "MerchantLabel"
	gui.Size = UDim2.new(0, 140, 0, 40)
	gui.StudsOffset = Vector3.new(0, 5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = merchant
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "MERCHANT"
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 213, 79)
	label.TextStrokeTransparency = 0.1
	label.Parent = gui

	-- The shop board next to the merchant lists the three items for sale.
	local board = Instance.new("Part")
	board.Name = "MerchantBoard"
	board.Size = Vector3.new(8, 6, 0.5)
	board.Position = Vector3.new(spot.X + 6, 3, spot.Z)
	board.Color = Color3.fromRGB(93, 64, 55)
	board.Material = Enum.Material.Wood
	board.Anchored = true
	board.Parent = world.folder
	local boardGui = Instance.new("SurfaceGui")
	boardGui.Name = "ShopGui"
	boardGui.Face = Enum.NormalId.Front
	boardGui.Parent = board
	local title = Instance.new("TextLabel")
	title.Name = "ShopTitle"
	title.Size = UDim2.new(1, 0, 0.25, 0)
	title.BackgroundTransparency = 1
	title.Text = "MERCHANT SHOP"
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.fromRGB(255, 213, 79)
	title.Parent = boardGui

	local stock = {}
	local stockButtons = {}

	local function updateBoard()
		for i = 1, STOCK_SIZE do
			local line = boardGui:FindFirstChild("ShopLine" .. tostring(i))
			local entry = stock[i]
			if not line then
				line = Instance.new("TextLabel")
				line.Name = "ShopLine" .. tostring(i)
				line.Size = UDim2.new(1, 0, 0.22, 0)
				line.Position = UDim2.new(0, 0, 0.24 + (i - 1) * 0.22, 0)
				line.BackgroundTransparency = 1
				line.TextScaled = true
				line.Font = Enum.Font.Gotham
				line.TextColor3 = Color3.fromRGB(255, 255, 255)
				line.Parent = boardGui
			end
			if entry then
				local price = math.floor(entry.price * PRICE_MULT)
				line.Text = tostring(i) .. ". " .. entry.name .. " - $" .. tostring(price)
			else
				line.Text = tostring(i) .. ". ---"
			end
		end
	end

	local function rotateStock()
		stock = {}
		local pool = {}
		for _, entry in ipairs(BrainrotData.Characters) do
			table.insert(pool, entry)
		end
		for i = 1, STOCK_SIZE do
			if #pool == 0 then
				break
			end
			local pick = math.random(1, #pool)
			table.insert(stock, pool[pick])
			table.remove(pool, pick)
		end
		updateBoard()
		events.MerchantStockChanged:Fire(stock)
	end

	-- Three click pads in front of the merchant, one per stock slot.
	for i = 1, STOCK_SIZE do
		local pad = Instance.new("Part")
		pad.Name = "StockPad" .. tostring(i)
		pad.Size = Vector3.new(3, 0.5, 3)
		pad.Position = Vector3.new(spot.X - 3 + (i - 1) * 3, 0.75, spot.Z + 4)
		pad.Color = Color3.fromRGB(255, 213, 79)
		pad.Material = Enum.Material.Neon
		pad.Anchored = true
		pad.CanCollide = false
		pad.Parent = world.folder
		stockButtons[i] = pad
		local detector = Instance.new("ClickDetector")
		detector.MaxActivationDistance = 24
		detector.Parent = pad
		detector.MouseClick:Connect(function(player)
			local entry = stock[i]
			if not entry then
				return
			end
			local price = math.floor(entry.price * PRICE_MULT)
			events.ChargeRequested:Fire(player, price, "merchant", { entryId = entry.id, price = price })
		end)
	end

	-- When the charge clears, build the character and hand it to BaseService
	-- through the same approved-purchase path the conveyor uses.
	events.ChargeApproved.Event:Connect(function(player, purpose, payload)
		if purpose ~= "merchant" then
			return
		end
		local entry = BrainrotData.getCharacter(payload.entryId)
		if not entry then
			events.Refund:Fire(player, payload.price or 0)
			return
		end
		local model = BrainrotModels.build(entry, "normal")
		events.PurchaseApproved:Fire(player, entry, "normal", payload.price, model, false)
	end)

	rotateStock()
	task.spawn(function()
		while true do
			task.wait(STOCK_INTERVAL)
			rotateStock()
			remotes.Notify:FireAllClients("The merchant has new stock!")
		end
	end)
end

return MerchantService
