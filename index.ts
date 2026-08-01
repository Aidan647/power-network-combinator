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
	if (!file.endsWith(".png")) continue
	console.log(`Processing ${file}...`)
	await sharp(filePath)
		.png({ compressionLevel: 9, force: true, palette: true, effort: 10 })
		.toBuffer()
		.then((buffer) => fs.writeFile(filePath, buffer))
		.catch((err) => console.error(`Error processing ${file}: ${err.message}`))
}
