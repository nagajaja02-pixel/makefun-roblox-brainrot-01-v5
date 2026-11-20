[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/nagajaja02-pixel/makefun-roblox-brainrot-01-v5/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/nagajaja02-pixel/makefun-roblox-brainrot-01-v5/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

# Brainrot Blitz

A 3D harbour tycoon game for the **roblox-brainrot-01** bounty on [make.fun](https://make.fun/bounty/roblox-brainrot-01). Buy absurd brainrot characters off a moving conveyor, park them on stands in your safehouse, and watch them earn money every second — while rival players try to steal them, a tsunami sweeps the island, and a shield keeps your base safe.

Play it live: https://www.roblox.com/games/105239944014039

The aerial thumbnail is live and approved on Roblox.

## The game

- **16 brainrot characters** with viral names, from Tung Tung Tung Sahur (Common) to Graipuss Medussi (Mythic), across five rarities — including three new Mythic additions: Giraffa Celeste, Bananita Dolphinita, and Graipuss Medussi.
- **Conveyor**: new brainrots roll out every few seconds and ride the belt from the west dock to the east gate. Click one to buy it.
- **Safehouses**: six bases around the island, each with stands for your brainrots. Start with 4 stands, upgrade up to 10.
- **Steal**: grab a brainrot off someone else's stand and carry it home. A shield blocks raids for 26 seconds, then needs a 48-second cooldown.
- **Baseball Bat**: every player spawns with a free wooden bat. Swing it at a raider to knock them back — if they are carrying a stolen brainrot, the hit makes them drop it and the raid fails.
- **Admin commands**: the owner (or anyone testing in Roblox Studio) can type `/golden` to spawn a Golden Brainrot at once, `/tsunami` to trigger a tsunami at once, or `/help` for the list. An admin event turns the sky golden (for `/golden`) or storm-dark (for `/tsunami`) and shows an "ADMIN EVENT" banner to every player.
- **Tsunami**: a wave sweeps the island on a schedule. Climb onto a base roof or the lookout deck to stay dry.
- **Mutations**: rare Gold (2x income), Diamond (3x income) and Rainbow (5x income) spawns.
- **Golden Brainrot event**: every few minutes a rare golden character appears on the conveyor, worth five times a normal character of its tier.
- **Rebirth**: reset your cash for a permanent +50% income, with a milestone bonus every 5 rebirths.
- **Leaderboard**: the three richest players are shown on the board in the middle of the island.
- **Merchant**: a travelling merchant by the dock sells three characters at a time at 1.25x price, with stock rotating every 90 seconds.

## Build

Requires [Rojo](https://rojo.space/) 7.x and Node 22.

```sh
rojo build -o game.rbxl
node main.ts
```

`rojo build` compiles `src/` into `game.rbxl`. `node main.ts` copies `game.rbxl`, `PLAY.json`, `src/` and `screenshots/` into the output directory and writes `dossier.json` there. The entrypoint never deletes the output directory; it only creates it if missing and copies into it.

## How to play

- You start with **$150** and **4 stands**.
- Buy brainrots from the conveyor, place them on stands, and earn money every second.
- Upgrade stands up to **10** (cost grows with the square of the stand count).
- Sell a character for **half** its buy price.
- Rebirth costs **$12,000 × (rebirths + 1)** and adds **+50%** income permanently.
- Activate your shield to block raids for 26 seconds; it needs a 48-second cooldown after it ends.
- When the tsunami warning sounds, get to high ground — the roofs and the observation deck are safe.
