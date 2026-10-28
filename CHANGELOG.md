# Changelog

## 1.0 — 2026-10-28

First release.

- `mw4-launch` starts the game from any launcher that runs Proton itself: put it
  in front of the launcher's command. Tested with Kryoto, Hydra, Faugus, Heroic,
  Steam and Lutris.
- Prepares `rex_sp.dll` (once), installs the fixed D3D12 DLLs, sets a fixed
  SteamID so saves keep loading, and runs `bin/codpatch` on the game at startup.
- Fixes low-resolution textures (`sp26/xpak_cache` link, Steam emulator
  connectivity settings) and turns HDR off.
- Runs the game in gamescope (SDL backend): no freeze or exit when switching
  windows, mouse captured from the start. GPU selection variables set by
  launchers are given to the game only, as they crash gamescope on hybrid-GPU
  laptops.
- Larger NVIDIA shader cache, NVAPI, GameMode, optional frame cap (`MW4_FPS_LIMIT`).
- Checks that would read large files are skipped once done.
- Logs in `~/.local/state/cod-mw4-linux/` for bug reports.
