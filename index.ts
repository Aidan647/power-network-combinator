import path from "node:path"
import fs from "node:fs/promises"
import sharp from "sharp"

const rootDir = process.argv[2]
if (!rootDir) {
	console.error("Usage: bun start <path-to-mod-directory>")
	process.exit(1)
}

const resolvedPath = path.resolve(rootDir)
try {
	const stat = await fs.stat(resolvedPath)
	if (!stat.isDirectory()) {
		console.error(`Error: "${resolvedPath}" is not a directory`)
		process.exit(1)
	}
} catch {
	console.error(`Error: "${resolvedPath}" does not exist`)
	process.exit(1)
}

// ----- run this on files before zipping -----

const files = await fs.readdir(resolvedPath, { recursive: true })

for (const file of files) {
	const filePath = path.join(resolvedPath, file)
	if (await fs.stat(filePath).then((stat) => !stat.isFile())) continue
	if (file.endsWith(".png")) 
		await proccessPng(filePath)
	if (file.endsWith(".lua"))
		await proccessLua(filePath)
	
}

async function proccessPng(file: string) {
	if (!file.endsWith(".png")) return
	console.log(`Processing ${file}...`)
	await sharp(file)
		.png({ compressionLevel: 9, force: true, palette: true, effort: 10 })
		.toBuffer()
		.then((buffer) => fs.writeFile(file, buffer))
		.catch((err) => console.error(`Error processing ${file}: ${err.message}`))
}

async function proccessLua(file: string) {
	if (!file.endsWith(".lua")) return
	const content = await fs.readFile(file, "utf-8")
	const lines = content.split("\n")
	const result: string[] = []
	for (let i = 0; i < lines.length; i++) {
		const line = lines[i]?.trim()
		if (line === undefined) break
		if (line === "") continue
		if (line.startsWith("--")) continue
		result.push(lines[i] ?? "")
	}
	const newContent = result.join("\n")
	if (newContent !== content) {
		await fs.writeFile(file, newContent, "utf-8")
		console.log(`Processed ${file}`)
	}

}