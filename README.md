# MW4 Linux Fix

Runs the offline campaign of **Call of Duty: Modern Warfare 4** (SP Offline V2 by
.r4v3n) on Linux, from the game launcher you already use.

The launcher keeps its own Proton and Wine prefix. `mw4-launch` goes in front of the
launcher's command and does the rest: it prepares the game files, starts the game in
gamescope and patches it in memory at startup, which replaces the Windows-only
Randgrid driver.

**Tested with** Kryoto, Hydra, Faugus 2.5, Heroic, Steam and Lutris 0.5.22, on CachyOS
with Hyprland and an NVIDIA RTX 3070 Laptop GPU (driver 615) next to an AMD iGPU.

## Contents

- [Requirements](#requirements)
- [Install](#install)
- [Launcher setup](#launcher-setup): [Kryoto & Hydra](#kryoto--hydra) ·
  [Steam](#steam) · [Heroic](#heroic) · [Lutris](#lutris) · [Faugus](#faugus) ·
  [Other launchers](#other-launchers)
- [Options](#options)
- [What it does](#what-it-does)
- [Performance](#performance)
- [Troubleshooting](#troubleshooting)
- [Uninstall](#uninstall)
- [Credits and license](#credits-and-license)

## Requirements

- **SP Offline V2 by .r4v3n** installed (its `sp26/rex_sp.dll`). This project does not
  include it.
- A launcher that runs the game with **Proton** (proton-cachyos, GE-Proton, Proton
  Experimental…).
- `gamescope`. Optional: `gamemode`.
- `python3` (first launch only).
- A Vulkan 1.3 GPU. NVIDIA and AMD work; Intel Arc should, but is unconfirmed.
- `kernel.yama.ptrace_scope` at 0 or 1, the default on most distributions. Otherwise:
  `sudo sysctl kernel.yama.ptrace_scope=1` (until reboot; to keep it, put
  `kernel.yama.ptrace_scope=1` in `/etc/sysctl.d/10-ptrace.conf`).

## Install

Download `mw4-linux-fix-<version>.zip` from the Releases page and extract it **into
the game folder**, next to `sp26/`. Nothing to `chmod`: launchers run `mw4-launch`
through `bash`.

Don't use the "Download source code" archive: it wraps everything in an extra folder.

On the first launch, shaders compile for several minutes with high CPU and RAM use.
The screen can stay black meanwhile: this is normal.

## Launcher setup

In every launcher, the executable is `sp26/sp26-cod.exe` and the game argument is
`hdeyguxs3zaumvlgvybm2vyc`. Leave the launcher's own gamescope, GameMode and MangoHud
**off**: `mw4-launch` already runs gamescope and GameMode, and a second gamescope
crashes the game. GPU options can stay on.

Replace `/path/to/game` with your game folder (the one that contains `sp26/`).

### Kryoto & Hydra

Launch options:

```
bash ./mw4-launch %command% hdeyguxs3zaumvlgvybm2vyc
```

`%command%` is replaced by the launcher's own command: type it as is. The game
argument must stay **after** it. Variables and tools go in front, for example
`prime-run bash ./mw4-launch %command% hdeyguxs3zaumvlgvybm2vyc`.

`./mw4-launch` works whether the working directory is the game folder or `sp26`
(there is a small relay in `sp26/`); otherwise, use the full path.

### Steam

Add `sp26/sp26-cod.exe` as a **non-Steam game**, then in its properties:

- Compatibility → **Force the use of a specific Steam Play compatibility tool**: on,
  with a Proton.
- Launch options:
  ```
  bash "/path/to/game/mw4-launch" %command% hdeyguxs3zaumvlgvybm2vyc
  ```

### Heroic

Add the game as a **Windows** game with `sp26/sp26-cod.exe` and a Proton as the Wine
version. In the game settings:

- Launcher arguments: `hdeyguxs3zaumvlgvybm2vyc`
- Advanced → **Wrapper command**: command `bash`, arguments
  `"/path/to/game/mw4-launch"` (with the quotes)

### Lutris

Add a locally installed game with the **Wine** runner:

- Game options: executable `sp26/sp26-cod.exe`, arguments `hdeyguxs3zaumvlgvybm2vyc`,
  any Wine prefix.
- Runner options: a **Proton** as the Wine version.
- System options (turn on "Show advanced options") → **Command prefix**:
  ```
  bash "/path/to/game/mw4-launch"
  ```

### Faugus

Edit the game → launch settings → **Launch Arguments**: a single line, then press
**Enter** before OK (Faugus drops a line that is still being edited):

```
bash "/path/to/game/mw4-launch"
```

Keep `hdeyguxs3zaumvlgvybm2vyc` in **Game arguments**. Don't add `gamescope`,
`prime-run` or `game-performance` there: Faugus' GPU option already picks the GPU.

### Other launchers

Any launcher that can put a Linux command **in front of** its own launch command
should work the same way: `bash "/path/to/game/mw4-launch"` in front, the game
argument after. A launcher that can only run the game through Wine, with no way to
add a Linux command in front, can't use this fix.

## Options

Environment variables, put in front of `bash …/mw4-launch` (or in the launcher's
environment settings):

| Variable | Effect |
|---|---|
| `MW4_FPS_LIMIT=60` | Caps the frame rate: less heat, noise and battery use. |
| `MW4_GAMESCOPE_ARGS="-W 2560 -H 1440 -r 165 -f --force-grab-cursor --backend sdl"` | gamescope options instead of the detected ones. Without `-f`, gamescope is a normal window you can move and resize. Keep `--backend sdl`. |
| `MW4_NO_GAMESCOPE=1` | Starts the game without gamescope, if gamescope doesn't work on your system. |
| `MW4_NO_GAMEMODE=1` | Doesn't use GameMode. |
| `COD_GAME_ROOT=/path/to/game` | Game folder, if it isn't found. |

## What it does

On every launch, `mw4-launch`:

1. **Prepares `sp26/rex_sp.dll`**, once. The original is kept as `sp26/rex_sp.dll.orig`.
2. **Installs the fixed D3D12 DLLs** from `runtime/` into `sp26/` and enables them.
3. **Sets a fixed SteamID** in `sp26/steam_settings/configs.user.ini` if it's empty, so
   saves keep loading. An ID that is already set is never changed.
4. **Turns HDR off** in the game settings (`…/Call of Duty/players/s.1.0.cod26.txt` in
   the prefix).
5. **Fixes low-resolution textures**: links `sp26/xpak_cache` to the game's
   `xpak_cache` (the Linux equivalent of the Windows `mklink /J` fix) and sets
   `disable_lan_only=1` and `offline=0` in `[main::connectivity]` of
   `sp26/steam_settings/configs.main.ini`.
6. **Patches the game in memory**: a few seconds after it starts, `bin/codpatch`
   attaches to it, applies the changes it needs to run without the Randgrid driver,
   and detaches. Nothing is attached or left running while you play.
7. **Starts the game in gamescope**, fullscreen at your screen's resolution and refresh
   rate, with its SDL backend. The game only sees gamescope's window, so you can
   switch windows, Alt+Tab or change workspace without it freezing or quitting, and
   the mouse is captured from the start. `PROTON_ENABLE_WAYLAND` is forced to 0, as
   gamescope needs it. GPU selection variables set by launchers (`DRI_PRIME`,
   `MESA_VK_DEVICE_SELECT`, `VK_DRIVER_FILES`, `VK_ICD_FILENAMES`) crash gamescope on
   hybrid-GPU laptops: gamescope starts without them and the game gets them back.

Every file it changes is saved first, with a `.orig` or `.pre-mw4-launch` suffix.
Steps 1 to 5 cost nothing once done.

The D3D12 DLLs are a patched vkd3d-proton: three shader compiler fixes, the
small-triangle cull switched off (it made faces look see-through at a distance), and
a fixed subgroup size of 32 for one shader that doesn't compile on Intel Arc
otherwise. Source and patches: `source/` and `SOURCE.txt`.

## Performance

`mw4-launch` also sets, unless you already set them:

- `__GL_SHADER_DISK_CACHE_SIZE=12000000000` and `__GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1`:
  NVIDIA's shader cache (`~/.cache/nvidia`) is limited to about 1 GB by default, too
  small for this game, so shaders got evicted and recompiled, causing stutter. No
  effect on AMD or Intel.
- `PROTON_ENABLE_NVAPI=1`: DLSS and Reflex on NVIDIA cards.
- **GameMode** (`gamemoderun`), when installed.

The biggest gains are in the game's own settings: DLSS (or FSR/XeSS) in
Quality/Balanced mode, ray tracing off (it costs a lot, as on Windows, and blocks
DLSS), and texture quality matched to your VRAM (8 GB cards should not use the
highest setting). On a laptop, `MW4_FPS_LIMIT` keeps it cooler and quieter.

## Troubleshooting

- **No sound with Bluetooth headphones.** When the game opens the microphone,
  WirePlumber switches the headset to its low-quality headset profile and the audio
  can drop for good. Keep it in A2DP:
  `wpctl settings --save bluetooth.autoswitch-to-headset-profile false`
  (`true` undoes it; the headset microphone then won't switch on by itself).
- **Black screen or gamescope crash at start**: try `MW4_GAMESCOPE_ARGS` without `-f`,
  or `MW4_NO_GAMESCOPE=1`. NVIDIA drivers older than 555 may not work with gamescope.
- **Mouse only captured after leaving the window and coming back**: if you set
  `MW4_GAMESCOPE_ARGS` yourself, keep `--backend sdl` in it.
- **Textures stay low-resolution**: if `sp26/xpak_cache` was already a folder with
  files in it, `mw4-launch` leaves it alone (see the log): move its content into the
  game's `xpak_cache`, delete it, and launch again.
- **Shaders recompile on every launch**: delete `sp26/vkd3d-proton.cache` and
  `sp26/shadercache`, then let one launch finish.

### Reporting a problem

Attach these files from `~/.local/state/cod-mw4-linux/`:

- `mw4-launch.log`: what `mw4-launch` did on the last launch. It ends with
  `codpatch: ready` when the patch worked, and with gamescope's exit code.
- `codpatch.log` and `gamescope.log`.
- If asked, `last-launch.env`: the environment the launcher gave `mw4-launch`. Check it
  first, it can contain personal paths or tokens.

Also useful: the Proton log (add `PROTON_LOG=1` in front of `bash …/mw4-launch`,
launch once, then take the `steam-*.log` file from your home folder), and, if the
game showed an error, the newest folder in
`<prefix>/drive_c/users/steamuser/AppData/Local/Temp/Activision/Call of Duty/`.

## Uninstall

1. Put `sp26/rex_sp.dll.orig` back as `sp26/rex_sp.dll`.
2. Put `sp26/steam_settings/configs.main.ini.pre-mw4-launch` back as
   `configs.main.ini` (and `configs.user.ini.pre-mw4-launch`, if present).
3. Delete `sp26/d3d12.dll`, `sp26/d3d12core.dll`, `sp26/mw4-launch` and the
   `sp26/xpak_cache` link, then the files from the zip in the game folder.
4. HDR can be turned back on from the game's settings.

## Credits and license

This is only a Linux layer. The offline campaign is **SP Offline V2 by .r4v3n**, and
all the credit for making it run offline goes to them. The startup patcher
(`bin/codpatch`) and the patched D3D12 DLLs come from the mw4linux "lumi" Linux fix.
vkd3d-proton (LGPL-2.1-or-later) and dxil-spirv (MIT) are by Hans-Kristian Arntzen
and contributors: see `SOURCE.txt` for the source, the patches and how to rebuild
the DLLs. "Call of Duty" is a trademark of Activision Publishing, Inc.; this project
is not affiliated with it.

### Building a release

The repository has the same layout as the game folder. `tools/make-release.sh` reads
the version from `MW4_LAUNCH_VERSION` in `mw4-launch`, checks the DLL hashes and the
scripts, and writes `dist/mw4-linux-fix-<version>.zip`. Note changes in
`CHANGELOG.md`.
