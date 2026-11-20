-- Game.client: the client entry point. It builds the HUD (cash, income,
-- rebirths, shield button, menu button, tsunami and golden banners, top
-- three, and a notification toast), wires the shield and menu buttons to
-- the server, runs a short camera intro on join, and hands the menu and
-- the carry pose to their own modules.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Menu = require(script.Parent.Menu)
local CarryPose = require(script.Parent.CarryPose)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function makeLabel(name, size, pos, text, fontSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = pos
	label.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	label.BackgroundTransparency = 0.3
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.1
	label.Parent = gui
	return label
end

local function makeButton(name, size, pos, text, color)
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
	button.Parent = gui
	return button
end

-- Top-left: cash, income per second, rebirths.
local cashLabel = makeLabel("CashLabel", UDim2.new(0, 260, 0, 44), UDim2.new(0, 12, 0, 12), "Cash: $150", 20)
local incomeLabel = makeLabel("IncomeLabel", UDim2.new(0, 260, 0, 36), UDim2.new(0, 12, 0, 62), "Income: $0/s", 18)
local rebirthLabel = makeLabel("RebirthLabel", UDim2.new(0, 260, 0, 36), UDim2.new(0, 12, 0, 104), "Rebirths: 0", 18)

-- Top-right: shield button and menu button.
local shieldButton = makeButton("ShieldButton", UDim2.new(0, 180, 0, 52), UDim2.new(1, -192, 0, 12), "SHIELD", Color3.fromRGB(41, 182, 246))
local menuButton = makeButton("MenuButton", UDim2.new(0, 180, 0, 52), UDim2.new(1, -192, 0, 72), "MENU", Color3.fromRGB(102, 187, 106))

-- Centre-top: tsunami and golden banners (hidden until an event fires).
local waveBanner = makeLabel("WaveBanner", UDim2.new(0, 520, 0, 52), UDim2.new(0.5, -260, 0, 12), "", 22)
waveBanner.Visible = false
waveBanner.BackgroundColor3 = Color3.fromRGB(2, 119, 189)
local goldenBanner = makeLabel("GoldenBanner", UDim2.new(0, 520, 0, 52), UDim2.new(0.5, -260, 0, 72), "", 22)
goldenBanner.Visible = false
goldenBanner.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
goldenBanner.TextColor3 = Color3.fromRGB(60, 40, 0)

-- Top-three board, under the banners.
local topLabel = makeLabel("TopLabel", UDim2.new(0, 260, 0, 96), UDim2.new(0.5, -130, 0, 132), "Richest:\n1. ---\n2. ---\n3. ---", 16)
topLabel.Visible = false

-- Bottom-centre toast for server notifications.
local toast = makeLabel("Toast", UDim2.new(0, 480, 0, 44), UDim2.new(0.5, -240, 1, -60), "", 18)
toast.Visible = false

local function showToast(message)
	toast.Text = message
	toast.Visible = true
	task.delay(4, function()
		toast.Visible = false
	end)
end

-- Leaderstats drive the cash, income and rebirth readouts.
local function bindStats()
	local stats = player:WaitForChild("leaderstats", 10)
	if not stats then
		return
	end
	local cash = stats:WaitForChild("Cash", 5)
	local income = stats:WaitForChild("Income", 5)
	local rebirths = stats:WaitForChild("Rebirths", 5)
	local function refresh()
		if cash then
			cashLabel.Text = "Cash: $" .. tostring(cash.Value)
		end
		if income then
			incomeLabel.Text = "Income: $" .. tostring(income.Value) .. "/s"
		end
		if rebirths then
			rebirthLabel.Text = "Rebirths: " .. tostring(rebirths.Value)
		end
	end
	if cash then
		cash:GetPropertyChangedSignal("Value"):Connect(refresh)
	end
	if income then
		income:GetPropertyChangedSignal("Value"):Connect(refresh)
	end
	if rebirths then
		rebirths:GetPropertyChangedSignal("Value"):Connect(refresh)
	end
	refresh()
end
task.spawn(bindStats)

shieldButton.MouseButton1Click:Connect(function()
	remotes.ShieldActivate:FireServer()
	shieldButton.Text = "SHIELD..."
	task.delay(1, function()
		shieldButton.Text = "SHIELD"
	end)
end)

menuButton.MouseButton1Click:Connect(function()
	Menu.toggle()
end)

remotes.WaveWarning.OnClientEvent:Connect(function(secondsLeft)
	waveBanner.Text = "TSUNAMI INCOMING! Get to high ground! " .. tostring(secondsLeft) .. "s"
	waveBanner.Visible = true
	task.delay(secondsLeft, function()
		waveBanner.Visible = false
	end)
end)

remotes.WaveSweep.OnClientEvent:Connect(function()
	waveBanner.Text = "TSUNAMI! Hold on!"
	waveBanner.Visible = true
	task.delay(8, function()
		waveBanner.Visible = false
	end)
end)

remotes.GoldenAnnounce.OnClientEvent:Connect(function(name, price)
	goldenBanner.Text = "GOLDEN BRAINROT! " .. name .. " - $" .. tostring(price) .. " on the conveyor!"
	goldenBanner.Visible = true
	task.delay(10, function()
		goldenBanner.Visible = false
	end)
end)

remotes.TopThree.OnClientEvent:Connect(function(top)
	local lines = { "Richest:" }
	for i = 1, 3 do
		local entry = top[i]
		if entry then
			lines[i + 1] = tostring(i) .. ". " .. entry.name .. " - $" .. tostring(entry.cash)
		else
			lines[i + 1] = tostring(i) .. ". ---"
		end
	end
	topLabel.Text = table.concat(lines, "\n")
	topLabel.Visible = true
end)

remotes.Notify.OnClientEvent:Connect(showToast)

-- Carry pose: watch the Carrying flag the server sets while we haul a steal.
CarryPose.watch(player)

-- Camera intro: a slow sweep over the harbour, then hands control back.
task.spawn(function()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local character = player.Character or player.CharacterAdded:Wait(5)
	if not character then
		return
	end
	local startPos = Vector3.new(-120, 40, -80)
	local endPos = Vector3.new(0, 25, 60)
	camera.CameraType = Enum.CameraType.Scriptable
	local steps = 60
	for i = 0, steps do
		local t = i / steps
		local pos = startPos:Lerp(endPos, t)
		camera.CFrame = CFrame.lookAt(pos, Vector3.new(0, 2, 0))
		RunService.RenderStepped:Wait()
	end
	camera.CameraType = Enum.CameraType.Custom
end)

Menu.setup(gui, remotes)
