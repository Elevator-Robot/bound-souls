# Bound Souls

## CI/CD deploy to itch.io

On every push to `main`, GitHub Actions runs `.github/workflows/deploy-itchio.yml` and:
1. Exports the game with Godot headless for `Linux/X11`, `Windows Desktop`, and `Web`
2. Creates zipped outputs:
   - `build/bound-souls-linux.zip`
   - `build/bound-souls-windows.zip`
   - `build/bound-souls-web.zip`
3. Uploads each zip to itch.io via butler channels:
   - `username/game:linux`
   - `username/game:windows`
   - `username/game:web`

### Required repository secrets

- `ITCHIO_API_KEY`: your itch.io API key for butler
- `ITCHIO_USERNAME`: your itch.io username (or org)
- `ITCHIO_GAME`: your itch.io game slug
