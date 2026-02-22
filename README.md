# Bound Souls

## CI/CD deploy to itch.io

On every push to `main`, GitHub Actions runs `.github/workflows/deploy-itchio.yml` and:
1. Exports the game with Godot headless using the `Web` preset from `export_presets.cfg`
2. Produces browser files in `build/web` (with `index.html` at root)
3. Uploads `build/web` to itch.io via butler channel `web` (`username/game:web`)

### Required repository secrets

- `ITCHIO_API_KEY`: your itch.io API key for butler
- `ITCHIO_USERNAME`: your itch.io username (or org)
- `ITCHIO_GAME`: your itch.io game slug
