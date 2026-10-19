# Vendored Clyde Luau obfuscator (dist only)

Source: https://github.com/sfr-development/Lua-Obfuscator-Clyde-Protection
Commit: 61f86b6c13dc089ea051b0a1511ba1b9b92d9af6
Vendored: 2026-10-19 (built `npm run build`, dist/ only — no node_modules needed for the obfuscate CLI)
License: MIT (see upstream)

CLI used by tools/obfuscate: `node tools/clyde/dist/cli/obfuscate.js --vm -o <out> <in>`
To update: re-clone upstream, `npm install && npm run build`, copy dist/ here, bump the commit above.
