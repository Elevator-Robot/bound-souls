# Bound Souls

## CI/CD deploy to itch.io

On every push to `main`, GitHub Actions runs `.github/workflows/deploy-itchio.yml` and:
1. Exports the game with Godot headless (`Linux/X11` preset from `export_presets.cfg`)
2. Creates `build/bound-souls-linux.zip`
3. Uploads that zip to itch.io using `butler`

### Required repository secrets

- `ITCHIO_API_KEY`: your itch.io API key for butler
- `ITCHIO_USERNAME`: your itch.io username (or org)
- `ITCHIO_GAME`: your itch.io game slug
- `ITCHIO_CHANNEL`: channel name (example: `linux`)
