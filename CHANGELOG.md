# Changelog

## 1.0.3 — 2026-11-10

- HD textures now download without IPv6: `bin/mw4-net.so` lets the game's texture
  downloads go out over IPv4 (`MW4_NO_NET_FIX=1` turns it off).
- Less VRAM used: the D3D12 DLLs no longer place small heaps in mostly empty
  16 MiB pools (patch from MW4-Proton).

## 1.0.2 — 2026-10-31

With `prime-run`:

- gamescope runs on the NVIDIA GPU: no more graphical glitches.
- Less shader stutter: the shader cache is kept per NVIDIA driver version.

Always:

- Menu clicks land on the cursor.
- The game always fills the screen.

## 1.0.1 — 2026-10-29

- With `prime-run`, the game runs on the NVIDIA GPU, not the integrated one.

## 1.0 — 2026-10-28

First release.

- Starts the game from any launcher that runs Proton: Kryoto, Hydra, Faugus,
  Heroic, Steam and Lutris tested.
- Prepares the game files and patches the game at startup.
- Fixes low-resolution textures and turns HDR off.
- Runs the game in gamescope: switching windows no longer freezes it.
- Performance options: larger NVIDIA shader cache, NVAPI, GameMode, optional
  frame cap.
- Logs for bug reports in `~/.local/state/cod-mw4-linux/`.
