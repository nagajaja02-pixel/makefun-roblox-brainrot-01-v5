-- BrainrotData: single source of truth for every tuning value in Brainrot Blitz.
-- Pure data plus pure helper functions. No service depends on this module's
-- callers, and this module depends on nobody, so requiring it can never cycle.
-- Every price, chance, timer and position the game uses lives here, in one
-- place, so the services can never disagree about the rules.

local BrainrotData = {}

-- Sixteen characters, cheapest first. Five rarities. Prices and incomes climb
-- with tier: Common costs tens and earns a few per second, Mythic costs
-- tens of thousands and earns over a thousand per second. Each entry carries
-- its own body colour and a one-line caption for the in-game label.
BrainrotData.Characters = {
	{ id = "tungtung", name = "Tung Tung Tung Sahur", tier = "Common", price = 40, income = 2, color = Color3.fromRGB(139, 90, 43), caption = "The log that knocks three times." },
	{ id = "boneca", name = "Boneca Ambalabu", tier = "Common", price = 65, income = 3, color = Color3.fromRGB(244, 143, 177), caption = "A little doll with a big stare." },
	{ id = "trippi", name = "Trippi Troppi", tier = "Common", price = 90, income = 5, color = Color3.fromRGB(66, 135, 245), caption = "A fish that never stops wiggling." },
	{ id = "lirili", name = "Lirili Larila", tier = "Rare", price = 150, income = 8, color = Color3.fromRGB(102, 187, 106), caption = "A cactus that hums its own name." },
	{ id = "frigo", name = "Frigo Camelo", tier = "Rare", price = 240, income = 12, color = Color3.fromRGB(236, 239, 241), caption = "A camel that keeps everything cool." },
	{ id = "chimpanzini", name = "Chimpanzini Bananini", tier = "Rare", price = 380, income = 18, color = Color3.fromRGB(255, 213, 79), caption = "A chimp who peels his own jokes." },
	{ id = "brrbrr", name = "Brr Brr Patapim", tier = "Epic", price = 650, income = 30, color = Color3.fromRGB(129, 212, 250), caption = "Cold as ice, twice as loud." },
	{ id = "ballerina", name = "Ballerina Cappuccina", tier = "Epic", price = 950, income = 45, color = Color3.fromRGB(240, 98, 146), caption = "She pirouettes on a coffee cup." },
	{ id = "cappuccino", name = "Cappuccino Assassino", tier = "Epic", price = 1400, income = 65, color = Color3.fromRGB(121, 85, 72), caption = "One sip and you are done for." },
	{ id = "orangutini", name = "Orangutini Ananasini", tier = "Legendary", price = 2400, income = 110, color = Color3.fromRGB(255, 152, 0), caption = "An orangutan in a pineapple suit." },
	{ id = "lavaca", name = "La Vaca Saturno Saturnita", tier = "Legendary", price = 3800, income = 170, color = Color3.fromRGB(149, 117, 205), caption = "A cow wearing a ringed planet." },
	{ id = "tralalero", name = "Tralalero Tralala", tier = "Legendary", price = 5500, income = 240, color = Color3.fromRGB(41, 121, 255), caption = "A shark that sings in threes." },
	{ id = "bombardiro", name = "Bombardiro Crocodilo", tier = "Mythic", price = 9000, income = 400, color = Color3.fromRGB(104, 159, 56), caption = "A crocodile with a bomber's payload." },
	{ id = "giraffa", name = "Giraffa Celeste", tier = "Mythic", price = 14000, income = 600, color = Color3.fromRGB(79, 195, 247), caption = "A sky-blue giraffe above the clouds." },
	{ id = "bananita", name = "Bananita Dolphinita", tier = "Mythic", price = 19000, income = 850, color = Color3.fromRGB(255, 241, 118), caption = "Half banana, half dolphin, all speed." },
	{ id = "graipuss", name = "Graipuss Medussi", tier = "Mythic", price = 25000, income = 1200, color = Color3.fromRGB(186, 104, 200), caption = "A jellyfish made of grapes." },
}

BrainrotData.Tiers = { "Common", "Rare", "Epic", "Legendary", "Mythic" }

-- Tier colours for labels and trims, so every system paints a tier the same way.
BrainrotData.TierColors = {
	Common = Color3.fromRGB(189, 189, 189),
	Rare = Color3.fromRGB(66, 165, 245),
	Epic = Color3.fromRGB(171, 71, 188),
	Legendary = Color3.fromRGB(255, 167, 38),
	Mythic = Color3.fromRGB(239, 83, 80),
}

-- Mutations. The rarer the mutation, the bigger the income multiplier.
-- Rainbow is the rarest of all at half a percent.
BrainrotData.Mutations = {
	{ id = "normal", mult = 1, chance = 0.925 },
	{ id = "gold", mult = 2, chance = 0.05 },
	{ id = "diamond", mult = 3, chance = 0.02 },
	{ id = "rainbow", mult = 5, chance = 0.005 },
}

BrainrotData.MutationColors = {
	normal = Color3.fromRGB(255, 255, 255),
	gold = Color3.fromRGB(255, 215, 0),
	diamond = Color3.fromRGB(185, 242, 255),
	rainbow = Color3.fromRGB(255, 105, 180),
}

-- Shield: lasts 26 seconds, then a 48 second cooldown counted AFTER it ends.
BrainrotData.Shield = { duration = 26, cooldown = 48 }

-- Conveyor: belt runs from -131 to +131 on X, a new character every 3.5 seconds,
-- moving at 4.2 studs per second.
BrainrotData.Conveyor = { spawnInterval = 3.5, speed = 4.2, minX = -131, maxX = 131 }

-- Tsunami: first wave 52 seconds in, 14 second warning, 8 second sweep,
-- then a new wave every 54 seconds.
BrainrotData.Wave = { firstAt = 52, warning = 14, sweep = 8, interval = 54 }

-- Golden Brainrot event: a rare golden character appears every 240 seconds,
-- worth five times a normal character of the same tier.
BrainrotData.Golden = { interval = 240, mult = 5 }

-- Economy: start with $150 and 4 stands, upgrade up to 10 stands.
-- Selling returns half the buy price. Rebirth costs 12000 times (rebirths + 1)
-- and adds 50% income; every 5 rebirths add another 25% permanent milestone.
BrainrotData.Economy = {
	startCash = 150,
	startStands = 4,
	maxStands = 10,
	sellFraction = 0.5,
	rebirthBase = 12000,
	rebirthBoost = 0.5,
	milestoneEvery = 5,
	milestoneBoost = 0.25,
}

-- Six safehouses: one mid-left, one mid-right, four at the corners.
BrainrotData.BasePositions = {
	Vector3.new(-82, 0, 0),
	Vector3.new(82, 0, 0),
	Vector3.new(-82, 0, -51),
	Vector3.new(82, 0, -51),
	Vector3.new(-82, 0, 51),
	Vector3.new(82, 0, 51),
}

BrainrotData.DataStoreName = "BlitzRebirthsV1"

-- The thirteen collision groups the shield service registers.
BrainrotData.CollisionGroups = {
	"Default",
	"Players",
	"Brainrots",
	"Shield",
	"Stands",
	"Conveyor",
	"Water",
	"Decor",
	"Bases",
	"Merchant",
	"Carry",
	"Wave",
	"Props",
}

-- Pure helpers below. They take numbers and return numbers, so any service
-- can call them without touching game state.

function BrainrotData.getCharacter(id)
	for _, entry in ipairs(BrainrotData.Characters) do
		if entry.id == id then
			return entry
		end
	end
	return nil
end

function BrainrotData.getCharactersByTier(tier)
	local out = {}
	for _, entry in ipairs(BrainrotData.Characters) do
		if entry.tier == tier then
			table.insert(out, entry)
		end
	end
	return out
end

-- Roll a mutation by its chances. Returns the mutation id.
function BrainrotData.rollMutation()
	local roll = math.random()
	local acc = 0
	for _, m in ipairs(BrainrotData.Mutations) do
		acc += m.chance
		if roll <= acc then
			return m.id
		end
	end
	return "normal"
end

function BrainrotData.mutationMult(id)
	for _, m in ipairs(BrainrotData.Mutations) do
		if m.id == id then
			return m.mult
		end
	end
	return 1
end

-- Income of one placed character, after its mutation multiplier.
function BrainrotData.characterIncome(entry, mutationId)
	return entry.income * BrainrotData.mutationMult(mutationId)
end

-- Rebirth price grows with the number of rebirths already done.
function BrainrotData.rebirthCost(rebirths)
	return BrainrotData.Economy.rebirthBase * (rebirths + 1)
end

-- Milestone bonus: +25% for every full set of 5 rebirths.
function BrainrotData.milestoneBonus(rebirths)
	return math.floor(rebirths / BrainrotData.Economy.milestoneEvery) * BrainrotData.Economy.milestoneBoost
end

-- Total income multiplier from rebirths and milestones.
function BrainrotData.incomeMultiplier(rebirths)
	return 1 + rebirths * BrainrotData.Economy.rebirthBoost + BrainrotData.milestoneBonus(rebirths)
end

-- Stand upgrade price rises with the square of the target stand count.
function BrainrotData.upgradeCost(currentStands)
	local target = currentStands + 1
	return 100 * target * target
end

-- Weighted random pick: cheaper tiers show up far more often than Mythic.
function BrainrotData.pickRandomCharacter()
	local weights = { Common = 45, Rare = 30, Epic = 15, Legendary = 7, Mythic = 3 }
	local total = 0
	for _, w in pairs(weights) do
		total += w
	end
	local roll = math.random() * total
	local acc = 0
	local chosenTier = "Common"
	for tier, w in pairs(weights) do
		acc += w
		if roll <= acc then
			chosenTier = tier
			break
		end
	end
	local pool = BrainrotData.getCharactersByTier(chosenTier)
	return pool[math.random(1, #pool)]
end

return BrainrotData
