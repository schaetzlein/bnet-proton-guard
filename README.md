# bnet-proton-guard

[![CI](https://github.com/schaetzlein/bnet-proton-guard/actions/workflows/ci.yml/badge.svg)](https://github.com/schaetzlein/bnet-proton-guard/actions/workflows/ci.yml)
[![Latest release](https://img.shields.io/github/v/release/schaetzlein/bnet-proton-guard)](https://github.com/schaetzlein/bnet-proton-guard/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Keeps **Battle.net running on Linux** (Steam + Proton). Backs up the Wine registry on every launch and repairs it automatically after a crash.

## The problem

When a Blizzard game crashes, the Wine registry of the Battle.net prefix (`system.reg`) can end up corrupted. Steam then shows *Running* for a second and Battle.net quits right away, with every Proton version. With `PROTON_LOG=1` the log shows:

```
system.reg is not a valid registry file
wine: '…/pfx' is a 32-bit installation, it cannot support 64-bit applications.
```

## The solution

bnet-proton-guard runs as the Steam launch option of your Battle.net shortcut, in front of Proton:

- **Every launch:** checks the registry. If it is healthy, it backs it up (the last 5 states). If it is broken, it restores the newest good backup and sends a desktop notification. Then Battle.net starts as usual.
- **`--rebuild`:** recreates the prefix and reinstalls Battle.net directly with Proton. Your Steam shortcut stays exactly as it is, and games installed outside the prefix are not touched.
- **`--kill`:** stops stuck processes. Only processes of this prefix are stopped, other running games are left alone.

It finds Steam (native, Flatpak, Snap), your Battle.net prefixes and your Proton versions (GE-Proton and Valve Proton) by itself, and only asks when it has to choose.

## Requirements

- Battle.net added to Steam as a non-Steam game, with a Proton version forced under *Properties → Compatibility*
- Bash 4+, coreutils, findutils (preinstalled on almost every distro)
- Optional: `notify-send` for desktop notifications

## Installation

```sh
curl -LO https://raw.githubusercontent.com/schaetzlein/bnet-proton-guard/main/bnet-proton-guard
bash bnet-proton-guard --setup
```

`--setup` finds your Battle.net prefix, installs the script to `~/.local/bin`, makes the first backup (or offers a repair if the registry is already broken) and prints the line for Steam.

Then in Steam: **Battle.net shortcut → Properties → Launch Options**

```
/home/<you>/.local/bin/bnet-proton-guard %command%
```

Alternatively, from a clone of this repository: `make install` (installs to `~/.local/bin`).

## Usage

| Command | Description |
|---|---|
| `bnet-proton-guard --setup` | Interactive setup |
| `bnet-proton-guard --check` | Check the registry and show backups |
| `bnet-proton-guard --backup` | Back up the registry now |
| `bnet-proton-guard --restore` | Restore the newest good backup |
| `bnet-proton-guard --kill` | Stop stuck processes of the prefix |
| `bnet-proton-guard --rebuild [Setup.exe]` | Recreate the prefix and reinstall Battle.net |
| `bnet-proton-guard --version` | Print the version |

Options (before the command): `--prefix DIR` uses a specific `…/steamapps/compatdata/<id>` folder, and `--yes` never asks. Set `NO_COLOR=1` to turn off colors and `BNET_GUARD_KEEP=N` to keep a different number of backups.

## Files

| Path | Content |
|---|---|
| `~/.config/bnet-proton-guard/config` | Selected prefix |
| `~/.local/share/bnet-proton-guard/<id>/` | Registry backups (`broken-*` folders keep replaced broken files) |
| `~/.local/share/bnet-proton-guard/bnet-proton-guard.log` | Log |

`XDG_CONFIG_HOME` and `XDG_DATA_HOME` are respected. Settings and backups of the old name `bnet-guard` are moved over automatically.

## FAQ / Troubleshooting

### Battle.net still quits right away

Run `bnet-proton-guard --check` in a terminal. If a file is reported as `BROKEN`, run `bnet-proton-guard --restore`. If there is no valid backup, run `bnet-proton-guard --rebuild`. If everything is `OK`, the registry is not the cause: start Battle.net with the launch option `PROTON_LOG=1 bnet-proton-guard %command%` and look at `~/steam-<appid>.log`.

### My games are gone after `--rebuild` – how do I get them back?

The games themselves are still there; only Battle.net forgot about them. Start Battle.net from Steam and log in. Then open the page of the game (not the home page) and click **"Locate the game"** below the Install button, and choose the game folder. Linux paths are reachable via drive `Z:`, for example:

```
Z:\home\you\Games\World of Warcraft
```

The *Scan for games* dialog on the home page often finds nothing under Wine, so use "Locate the game" instead.

### `--rebuild` does not find Battle.net-Setup.exe

It looks for the newest `Battle.net-Setup*.exe` in your download folder. Download it from <https://www.blizzard.com/download> or pass the path: `bnet-proton-guard --rebuild /path/to/Battle.net-Setup.exe`.

### Which Proton does `--rebuild` use?

GE-Proton is listed first (newest first), then Valve Proton. In a terminal you can choose; with `--yes` the first one is used. Use the same Proton version as the one forced in Steam.

### I have several Battle.net prefixes

`--setup` asks which one to use and stores it in the config. As a launch option the guard always uses the prefix Steam passes in (`STEAM_COMPAT_DATA_PATH`), so each shortcut gets its own backups.

### Battle.net or the installer hangs

`bnet-proton-guard --kill` stops all processes that run in this prefix (`WINEPREFIX` matches). Other games and other prefixes are not affected.

### Does it work with Lutris, Heroic or plain Wine?

It is built for Steam with Proton. `--check`, `--backup` and `--restore` work on any Proton prefix passed with `--prefix`; the launch option and `--rebuild` expect Steam.

## Contributing

Bug reports and pull requests are welcome, see [CONTRIBUTING.md](CONTRIBUTING.md). Run `make lint test` before submitting.

## Disclaimer

This project is not affiliated with, endorsed or sponsored by Blizzard Entertainment or Valve Corporation. Battle.net, World of Warcraft and Blizzard are trademarks of Blizzard Entertainment, Inc. Steam and Proton are trademarks of Valve Corporation.

## License

[MIT](LICENSE) © Lukas Schätzlein
