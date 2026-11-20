-- ShieldService: the laser shield around each safehouse. When a player
-- activates it, the shell turns visible and solid for 26 seconds, and no
-- rival can walk in to steal. After it ends, a 48 second cooldown runs —
-- counted from the moment the shield ends, not from activation — so a full
-- cycle is 74 seconds. The shell's solidity always matches its visibility:
-- a transparent shell must never be solid, or the collision groups below
-- would block players the shield is supposed to let through.

local PhysicsService = game:GetService("PhysicsService")
local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)

local ShieldService = {}

-- player -> { endsAt, readyAgainAt } in os.clock() seconds.
local shields = {}

local function setShell(base, visible)
	local shell = base.shell
	if not shell then
		return
	end
	-- Visibility and solidity are set together, always. This is the rule
	-- that makes the collision groups below actually matter.
	shell.Transparency = visible and 0.5 or 1
	shell.CanCollide = visible
end

function ShieldService.init(ctx)
	local world = ctx.world
	local events = ctx.events
	local remotes = ctx.remotes

	-- Thirteen collision groups. The shield only ever blocks people: it
	-- collides with Players and with carried brainrots, and with nothing
	-- else, so it never stops a character being placed or a decoration
	-- from sitting where it belongs.
	for _, name in ipairs(BrainrotData.CollisionGroups) do
		pcall(function()
			PhysicsService:RegisterCollisionGroup(name)
		end)
	end
	for _, other in ipairs(BrainrotData.CollisionGroups) do
		if other ~= "Shield" then
			local blocks = (other == "Players") or (other == "Carry")
			pcall(function()
				PhysicsService:CollisionGroupSetCollidable("Shield", other, blocks)
			end)
		end
	end

	local function baseOf(player)
		local baseService = ctx.services.BaseService
		local index = baseService.getBaseIndex(player)
		if not index then
			return nil
		end
		return world.bases[index]
	end

	remotes.ShieldActivate.OnServerEvent:Connect(function(player)
		local base = baseOf(player)
		if not base then
			remotes.Notify:FireClient(player, "Claim a base first!")
			return
		end
		local now = os.clock()
		local record = shields[player]
		if record and now < record.readyAgainAt then
			local left = math.ceil(record.readyAgainAt - now)
			remotes.Notify:FireClient(player, "Shield cooling down: " .. tostring(left) .. "s left.")
			return
		end
		-- endsAt is activation plus 26; readyAgainAt is endsAt plus 48.
		local endsAt = now + BrainrotData.Shield.duration
		local readyAgainAt = endsAt + BrainrotData.Shield.cooldown
		shields[player] = { endsAt = endsAt, readyAgainAt = readyAgainAt }
		setShell(base, true)
		events.ShieldChanged:Fire(player, true)
		remotes.Notify:FireClient(player, "Shield up for 26 seconds!")
	end)

	-- Watcher: hide every shield the moment its 26 seconds are over.
	task.spawn(function()
		while true do
			task.wait(0.5)
			local now = os.clock()
			for player, record in pairs(shields) do
				if now >= record.endsAt then
					local base = baseOf(player)
					if base then
						setShell(base, false)
					end
					shields[player] = { endsAt = 0, readyAgainAt = record.readyAgainAt }
					events.ShieldChanged:Fire(player, false)
				end
			end
		end
	end)
end

function ShieldService.isShieldActive(player)
	local record = shields[player]
	if not record then
		return false
	end
	return os.clock() < record.endsAt
end

function ShieldService.isShieldReady(player)
	local record = shields[player]
	if not record then
		return true
	end
	return os.clock() >= record.readyAgainAt
end

return ShieldService
