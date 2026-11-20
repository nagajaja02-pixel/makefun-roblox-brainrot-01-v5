// Brainrot Blitz entrypoint.
//
// Copies the built place, the play link, the sources and the screenshots
// into the output directory, then writes the dossier buildDossier computes
// from them. The dossier must be byte-identical to what the scorer
// computes from the same files, so this program only copies and writes —
// it never edits, filters or reorders anything.
//
// HARD RULE about the output directory, learned the expensive way: this
// program must NEVER delete the output directory. The grader runs as a
// user who may write INSIDE the output directory but may NOT remove the
// directory itself (deleting it needs write permission on its parent), so
// a rmSync on the output directory crashes the whole entry with EACCES
// and exit code 1. Only mkdir (recursive) plus copy-in plus overwrite.
// There is no rmSync, no rm and no unlink anywhere in this file.
import { cpSync, existsSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { buildDossier } from "./vendor/makefun-roblox.ts";

const outDir = process.env.MAKEFUN_OUTPUT_DIR ?? "/output";

// Create the output directory if it is missing. Never delete it.
mkdirSync(outDir, { recursive: true });

// Copy the entry into the output directory, overwriting what is there.
for (const name of ["game.rbxl", "PLAY.json", "src", "screenshots"]) {
	cpSync(name, join(outDir, name), { recursive: true });
}

// Write the dossier the scorer will compare against its own computation.
writeFileSync(join(outDir, "dossier.json"), buildDossier(outDir, { text_max_bytes: 65536 }));

// Sanity check: the place file must have landed in the output directory.
if (!existsSync(join(outDir, "game.rbxl"))) {
	throw new Error("game.rbxl missing from output after copy");
}
