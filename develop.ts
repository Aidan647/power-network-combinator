import { existsSync, statSync } from "node:fs"
import { readlink, unlink, symlink, mkdir } from "node:fs/promises"
import { resolve } from "node:path"
import { spawn, type ChildProcess } from "node:child_process"
import info from "./src/info.json" with { type: "json" }

const MOD_NAME = info.name
const SRC_DIR = resolve("./src")

// --- Helpers ---

function parseArgs() {
	const args = process.argv.slice(2)
	const bin = args[0]
	const saveIdx = args.indexOf("--save")
	const save = saveIdx !== -1 ? args[saveIdx + 1] : undefined
	const exitOnLoad = args.includes("--exit")
	const headless = args.includes("--headless")
	return { bin, save, exitOnLoad, headless }
}

function resolveSavePath(factorioRoot: string, name: string) {
	const savesDir = resolve(factorioRoot, "saves")
	const zipName = name.endsWith(".zip") ? name : `${name}.zip`
	return resolve(savesDir, zipName)
}

function resolveFactorio(binPath: string) {
	let factorioBin = binPath
	let factorioRoot: string

	if (existsSync(factorioBin) && statSync(factorioBin).isDirectory()) {
		factorioRoot = resolve(factorioBin)
		const candidate = resolve(factorioRoot, "bin/x64/factorio")
		if (!existsSync(candidate)) {
			console.error(`Factorio binary not found at: ${candidate}`)
			process.exit(1)
		}
		factorioBin = candidate
	} else {
		factorioRoot = resolve(factorioBin, "..", "..", "..")
	}

	if (!existsSync(factorioBin)) {
		console.error(`Factorio binary not found at: ${factorioBin}`)
		process.exit(1)
	}

	return { factorioBin, factorioRoot }
}

async function ensureSymlink(factorioRoot: string) {
	const modLink = resolve(factorioRoot, "mods", MOD_NAME)
	await mkdir(resolve(factorioRoot, "mods"), { recursive: true })

	if (existsSync(modLink)) {
		const existing = await readlink(modLink)
		if (existing !== SRC_DIR) {
			await unlink(modLink)
			await symlink(SRC_DIR, modLink)
		}
	} else {
		await symlink(SRC_DIR, modLink)
	}
}

function launch(bin: string, args: string[], waitFor?: string): ChildProcess {
	const proc = spawn(bin, args, { stdio: ["inherit", "pipe", "inherit"] })

	let killed = false
	if (waitFor) {
		let buffer = ""
		proc.stdout!.on("data", (chunk: Buffer) => {
			const text = chunk.toString()
			process.stdout.write(text)
			buffer += text
			if (buffer.includes(waitFor)) {
				killed = true
				setTimeout(() => proc.kill("SIGTERM"), 500)
			}
		})
	} else {
		proc.stdout!.pipe(process.stdout)
	}

	proc.on("exit", (code) => {
		if (!killed) console.log(`\nFactorio exited with code ${code}`)
		else console.log(`\nFactorio closed as requested`)
	})
	process.on("SIGINT", () => proc.kill("SIGINT"))
	process.on("SIGTERM", () => proc.kill("SIGTERM"))
	return proc
}

// --- Main ---

const { bin, save, exitOnLoad, headless } = parseArgs()

if (!bin) {
	console.error("Usage: bun run develop /path/to/factorio [--save <file>] [--exit] [--headless]")
	console.error("  --headless  Start as server (--start-server) for faster testing")
	process.exit(1)
}

const { factorioBin, factorioRoot } = resolveFactorio(bin)
await ensureSymlink(factorioRoot)

const factorioArgs: string[] = []
if (headless) {
	if (save) factorioArgs.push("--start-server", resolveSavePath(factorioRoot, save))
	else factorioArgs.push("--start-server-load-latest")
} else {
	factorioArgs.push("--fullscreen=false")
	if (save) factorioArgs.push("--load-game", resolveSavePath(factorioRoot, save))
}

const waitFor = exitOnLoad ? (save ? "Checksum for script" : "Factorio initialised") : undefined
launch(factorioBin, factorioArgs, waitFor)
