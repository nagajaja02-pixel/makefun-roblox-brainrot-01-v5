-- Menu: the in-game menu. One panel with four sections: rebirth, stand
-- upgrades, the sixteen-character index, and a sell grid for the ten
-- stands. The index is built from the same BrainrotData the server uses,
-- so the prices it shows are the prices the game charges. Selling and
-- buying stands go through the server remotes, which validate everything.

local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)

local Menu = {}

local frame = nil
local remotes = nil
local open = false

local function makeButton(parent, name, size, pos, text, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = pos
	button.BackgroundColor3 = color
	button.Text = text
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextStrokeTransparency = 0.1
	button.Parent = parent
	return button
end

local function makeLabel(parent, name, size, pos, text)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = pos
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.Gotham
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.1
	label.Parent = parent
	return label
end

function Menu.setup(gui, remoteTable)
	remotes = remoteTable
	frame = Instance.new("Frame")
	frame.Name = "BrainrotMenu"
	frame.Size = UDim2.new(0, 560, 0, 640)
	frame.Position = UDim2.new(0.5, -280, 0.5, -320)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 0.1
	frame.Visible = false
	frame.Parent = gui

	makeLabel(frame, "MenuTitle", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), "BRAINROT BLITZ")
	local closeButton = makeButton(frame, "CloseButton", UDim2.new(0, 44, 0, 44), UDim2.new(1, -44, 0, 0), "X", Color3.fromRGB(239, 83, 80))
	closeButton.MouseButton1Click:Connect(function()
		Menu.toggle()
	end)

	-- Rebirth and stand upgrades.
	local rebirthButton = makeButton(frame, "RebirthButton", UDim2.new(0, 260, 0, 48), UDim2.new(0, 12, 0, 56), "REBIRTH (+50% income)", Color3.fromRGB(171, 71, 188))
	rebirthButton.MouseButton1Click:Connect(function()
		remotes.Rebirth:FireServer()
	end)
	local standButton = makeButton(frame, "StandButton", UDim2.new(0, 260, 0, 48), UDim2.new(1, -272, 0, 56), "BUY STAND (up to 10)", Color3.fromRGB(66, 165, 245))
	standButton.MouseButton1Click:Connect(function()
		remotes.BuyStand:FireServer()
	end)
	makeLabel(frame, "MenuHint", UDim2.new(1, -24, 0, 28), UDim2.new(0, 12, 0, 112), "Rebirth costs $12,000 x (rebirths + 1). Every 5 rebirths: +25% milestone.", 14)

	-- Character index: all sixteen, cheapest first.
	makeLabel(frame, "IndexTitle", UDim2.new(1, 0, 0, 32), UDim2.new(0, 12, 0, 148), "CHARACTER INDEX (16)", 18)
	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "IndexScroller"
	scroller.Size = UDim2.new(1, -24, 0, 240)
	scroller.Position = UDim2.new(0, 12, 0, 184)
	scroller.BackgroundTransparency = 1
	scroller.ScrollBarThickness = 6
	scroller.CanvasSize = UDim2.new(0, 0, 0, 16 * 28)
	scroller.Parent = frame
	for i, entry in ipairs(BrainrotData.Characters) do
		local row = Instance.new("TextLabel")
		row.Name = "IndexRow" .. tostring(i)
		row.Size = UDim2.new(1, 0, 0, 26)
		row.Position = UDim2.new(0, 0, 0, (i - 1) * 28)
		row.BackgroundTransparency = 1
		row.Text = tostring(i) .. ". " .. entry.name .. " [" .. entry.tier .. "] - $" .. tostring(entry.price) .. " - $" .. tostring(entry.income) .. "/s"
		row.TextScaled = true
		row.Font = Enum.Font.Gotham
		row.TextColor3 = BrainrotData.TierColors[entry.tier] or Color3.fromRGB(255, 255, 255)
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Parent = scroller
	end

	-- Sell grid: ten slots. Clicking one asks the server to sell whatever
	-- sits on that stand (the server checks it is really yours).
	makeLabel(frame, "SellTitle", UDim2.new(1, 0, 0, 32), UDim2.new(0, 12, 0, 432), "SELL A STAND (half price back)", 18)
	for slot = 1, 10 do
		local col = (slot - 1) % 5
		local row = math.floor((slot - 1) / 5)
		local sellButton = makeButton(frame, "SellSlot" .. tostring(slot), UDim2.new(0, 100, 0, 40), UDim2.new(0, 12 + col * 108, 0, 468 + row * 48), "Sell " .. tostring(slot), Color3.fromRGB(255, 152, 0))
		sellButton.MouseButton1Click:Connect(function()
			remotes.SellCharacter:FireServer(slot)
		end)
	end

	-- Merchant note: the shop itself lives at the dock in the world.
	makeLabel(frame, "MerchantNote", UDim2.new(1, -24, 0, 28), UDim2.new(0, 12, 0, 576), "Merchant by the dock: 3 characters, 1.25x price, stock rotates every 90s.", 14)
	makeLabel(frame, "GoldenNote", UDim2.new(1, -24, 0, 28), UDim2.new(0, 12, 0, 604), "Golden Brainrot appears every few minutes: 5x price and income!", 14)
end

function Menu.toggle()
	if not frame then
		return
	end
	open = not open
	frame.Visible = open
end

return Menu
