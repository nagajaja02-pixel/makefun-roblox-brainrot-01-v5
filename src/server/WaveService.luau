-- WaveService: the tsunami. The first wave arrives 52 seconds after the
-- server starts. Every wave gives a 14 second evacuation warning, then an
-- 8 second wall of water sweeps the island from west to east, and the next
-- wave follows 54 seconds later. Anyone caught below the high ground when
-- the wall passes is swept back to their own base — so the roofs and the
-- observation deck are the only safe places when the siren sounds.

local Players = game:GetService("Players")
local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)

local WaveService = {}

local SAFE_HEIGHT = 8

function WaveService.init(ctx)
	local world = ctx.world
	local events = ctx.events
	local remotes = ctx.remotes
	local baseService = ctx.services.BaseService

	-- The wall itself: one big translucent slab, parked off the island
	-- until a wave starts, then driven across it.
	local wall = Instance.new("Part")
	wall.Name = "TsunamiWall"
	wall.Size = Vector3.new(16, 26, 200)
	wall.Position = Vector3.new(-200, 11, 0)
	wall.Color = Color3.fromRGB(2, 119, 189)
	wall.Material = Enum.Material.Water
	wall.Transparency = 0.35
	wall.Anchored = true
	wall.CanCollide = false
	wall.Parent = world.folder

	local function sweepPlayer(player, waveX)
		local character = player.Character
		if not character then
			return
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		-- High ground is safe: roofs and the observation deck sit above it.
		if root.Position.Y >= SAFE_HEIGHT then
			return
		end
		if math.abs(root.Position.X - waveX) > 12 then
			return
		end
		local baseIndex = baseService.getBaseIndex(player)
		if baseIndex then
			local base = world.bases[baseIndex]
			root.CFrame = CFrame.new(base.position + Vector3.new(0, 3, 10))
			remotes.Notify:FireClient(player, "The tsunami swept you back to your base!")
		end
	end

	-- One wave may run at a time. The flag is declared before runWave
	-- so the function captures this local (not a global).
	local waveRunning = false

	-- The wave body: warning, then the sweep, then the wall parks off the
	-- island again. Assumes the wave slot is already claimed; clears it
	-- at the end so the next wave may start.
	local function runWave()
		-- Warning: fourteen seconds to get to high ground.
		events.WaveWarning:Fire(BrainrotData.Wave.warning)
		remotes.WaveWarning:FireAllClients(BrainrotData.Wave.warning)
		task.wait(BrainrotData.Wave.warning)
		-- Sweep: eight seconds, the wall crosses the island west to east.
		events.WaveSweep:Fire()
		remotes.WaveSweep:FireAllClients()
		local steps = 16
		local stepTime = BrainrotData.Wave.sweep / steps
		for i = 0, steps do
			local x = -140 + (280 * i / steps)
			wall.Position = Vector3.new(x, 11, 0)
			for _, player in ipairs(Players:GetPlayers()) do
				sweepPlayer(player, x)
			end
			task.wait(stepTime)
		end
		wall.Position = Vector3.new(-200, 11, 0)
		waveRunning = false
	end

	-- Claim the wave slot; returns false when a wave is already running,
	-- so two waves can never run at once.
	local function claimWave()
		if waveRunning then
			return false
		end
		waveRunning = true
		return true
	end

	-- Public trigger so the admin service can start a wave on demand.
	-- Returns false when a wave is already running.
	WaveService.triggerWave = function()
		if not claimWave() then
			return false
		end
		task.spawn(runWave)
		return true
	end

	-- Scheduled waves: the first one 52 seconds after the server starts,
	-- then fifty-four seconds of calm after each wave before the next.
	task.spawn(function()
		task.wait(BrainrotData.Wave.firstAt)
		while true do
			if claimWave() then
				runWave()
			end
			task.wait(BrainrotData.Wave.interval)
		end
	end)
end

return WaveService
