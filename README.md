# Bound Souls

## Open in Summer Engine

This is an existing Godot 4.4 / GL Compatibility project. Summer's documented
existing-project workflow keeps **`project.godot` as the project file**; it does
not prescribe a replacement `project.summer` or project-level
`.summer/config.json`. The first import still needs testing in your Summer
editor version.

1. Install the desktop app from [Summer Engine's download page](https://www.summerengine.com/download).
   As of October 2026, native downloads are offered for Apple-silicon macOS and
   Windows, not Linux.
2. Clone this repository, then use Summer's Project Manager → Import to select
   the existing `project.godot`. Do not create a new template over it.
3. Wait for the initial import/indexing to finish. Run the main scene (F6 with
   `scenes/main/main.tscn` open) or the project (F5), and check the debugger for
   script/resource errors. Verify the world, player movement, and battle entry.
4. Review `git diff` after the first open. Keep the current GL Compatibility
   renderer and review any engine-version, `.import`, or export-preset changes
   deliberately; a newer upstream base alone does not prove compatibility.

See Summer's [existing-project guide](https://docs.summerengine.com/quickstarts/existing-godot)
and [compatibility guidance](https://docs.summerengine.com/knowledge-base/godot-compatibility).
Test exports separately with the templates matching the editor used to export.

### Optional CLI and AI-agent connection

The desktop workflow above needs no Node.js or MCP configuration. For the
external-agent workflow, install **Node.js 22+** and run from this repository's
root (after installing the Summer desktop app):

```sh
npx -y summer-engine@4.8.0 run .
npx -y summer-engine@4.8.0 status
```

`.mcp.json` supplies the local Summer MCP server for clients that read that
format, such as Claude Code. It configures the external agent connection, not
native editor project initialization. Start the client in this repository and approve
the project server when prompted. `--project .` binds it to this checkout;
do not launch it with another working directory. Other clients need their own
setup; for example, to install Summer's Codex integration and skills:

```sh
npx -y summer-engine@4.8.0 setup codex --channel 4.8.0 --yes
```

The pinned **4.8.0 is the CLI/MCP package version**, not the desktop engine
version. Update the pin and commands together after checking a new release.
An agent's Summer project-context tool should report this checkout before it
edits anything. See the [official CLI documentation](https://docs.summerengine.com/mcp/cli).

Summer's global configuration and credentials belong in `~/.summer/`, not this
repository. The optional `.summer/project.json` records template provenance;
this project was not created from a Summer template, so no template manifest
is invented. Shared `.summer/` project memory can be committed, while local
state, screenshots, captures, and exports are ignored.

### Godot compatibility smoke check

The original Godot workflow remains available. Import assets before running a
fresh checkout, and treat logged errors as failures even if the editor exits 0:

```sh
godot --headless --editor --path . --import
godot --headless --path . --quit-after 120
```

This checks startup, not gameplay or native Summer compatibility. Run the
Summer editor checks above as well; Summer-only SDK or runtime features would
also require revisiting the Godot-based deployment below.

## CI/CD deploy to itch.io

On every push to `main`, GitHub Actions runs `.github/workflows/deploy-itchio.yml` and:
1. Exports the game with Godot headless using the `Web` preset from `export_presets.cfg`
2. Produces browser files in `build/web` (with `index.html` at root)
3. Uploads `build/web` to itch.io via butler channel `html5` (`username/game:html5`)

### Required repository secrets

- `ITCHIO_API_KEY`: your itch.io API key for butler
- `ITCHIO_USERNAME`: your itch.io username (or org)
- `ITCHIO_GAME`: your itch.io game slug
