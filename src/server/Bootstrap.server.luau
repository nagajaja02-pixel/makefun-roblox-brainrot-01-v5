-- Bootstrap: the server entry point. It builds the island, creates the
-- server event bus (BindableEvents) and the client remotes (RemoteEvents),
-- then starts every service with the same context table so the services can
-- find each other through ctx.services instead of requiring each other —
-- which is what keeps the module graph free of cycles.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local World = require(script.Parent.World)
local BrainrotModels = require(script.Parent.BrainrotModels)
local ConveyorService = require(script.Parent.ConveyorService)
local BaseService = require(script.Parent.BaseService)
local MoneyService = require(script.Parent.MoneyService)
local StealService = require(script.Parent.StealService)
local ShieldService = require(script.Parent.ShieldService)
local WaveService = require(script.Parent.WaveService)
local MerchantService = require(script.Parent.MerchantService)

-- Server bus: BindableEvents the services use to talk to each other.
local busFolder = Instance.new("Folder")
busFolder.Name = "BrainrotBus"
busFolder.Parent = ServerScriptService
local events = {}
for _, name in ipairs({
	"PurchaseRequested",
	"PurchaseApproved",
	"PurchaseDenied",
	"Refund",
	"ChargeRequested",
	"ChargeApproved",
	"ChargeDenied",
	"CharacterPlaced",
	"CharacterRemoved",
	"SellRequested",
	"ShieldChanged",
	"WaveWarning",
	"WaveSweep",
	"MerchantStockChanged",
}) do
	local event = Instance.new("BindableEvent")
	event.Name = name
	event.Parent = busFolder
	events[name] = event
end

-- Client remotes: RemoteEvents the client scripts use to talk to the server
-- and the server uses to push updates to the clients.
local remoteFolder = Instance.new("Folder")
remoteFolder.Name = "BrainrotRemotes"
remoteFolder.Parent = ReplicatedStorage
local remotes = {}
for _, name in ipairs({
	"ShieldActivate",
	"BuyStand",
	"SellCharacter",
	"Rebirth",
	"BuyMerchant",
	"WaveWarning",
	"WaveSweep",
	"GoldenAnnounce",
	"TopThree",
	"Notify",
}) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remoteFolder
	remotes[name] = remote
end

-- Build the island first: every service works with the world it returns.
local world = World.build()

-- The context every service receives. The services table is filled before
-- any init runs, so a service can call a sibling through ctx.services.
local ctx = {
	world = world,
	events = events,
	remotes = remotes,
	services = {},
}

ctx.services.World = World
ctx.services.BrainrotModels = BrainrotModels
ctx.services.ConveyorService = ConveyorService
ctx.services.BaseService = BaseService
ctx.services.MoneyService = MoneyService
ctx.services.StealService = StealService
ctx.services.ShieldService = ShieldService
ctx.services.WaveService = WaveService
ctx.services.MerchantService = MerchantService

-- Start the services. BaseService first (it owns the safehouses the other
-- services place things into), then the economy, then the rest.
BaseService.init(ctx)
MoneyService.init(ctx)
ConveyorService.init(ctx)
StealService.init(ctx)
ShieldService.init(ctx)
WaveService.init(ctx)
MerchantService.init(ctx)

-- Heartbeat: a light status line every minute, so the server log shows the
-- game is alive and how many players are in.
task.spawn(function()
	while true do
		task.wait(60)
		local count = #game:GetService("Players"):GetPlayers()
		print("[Brainrot Blitz] heartbeat: " .. tostring(count) .. " players in game")
	end
end)

print("[Brainrot Blitz] server started: island built, 8 services running")
