# bnet-proton-guard

A small helper that keeps **Battle.net running on Linux** with Steam and Proton.

Many people run Battle.net as a non-Steam game in Steam, with Proton (the tool
Steam uses to run Windows programs on Linux). When a Blizzard game crashes,
Battle.net often won't start anymore: Steam shows *Running* for a second and
then nothing happens, with every Proton version. bnet-proton-guard prevents
this. It backs up Battle.net's Wine registry every time you start it and
repairs it automatically when a crash has broken it.

> **Note:** This is an unofficial community project. It is not affiliated
> with, endorsed or sponsored by Blizzard Entertainment or Valve Corporation.
> Battle.net, World of Warcraft and Blizzard are trademarks of Blizzard
> Entertainment, Inc. Steam and Proton are trademarks of Valve Corporation.

## The problem

Proton keeps Battle.net's Windows settings in a folder of its own, the
*prefix*. The most important files in it are the **Wine registry** files
(`system.reg`, `user.reg`, `userdef.reg`). If a game crashes while Wine is
writing them, they can end up broken, for example full of null bytes. Wine
then can't read them and Battle.net quits right away. Starting Proton with
`PROTON_LOG=1` shows lines like these:

```text
system.reg is not a valid registry file
wine: '…/pfx' is a 32-bit installation, it cannot support 64-bit applications.
```

## What it does

bnet-proton-guard runs in front of Battle.net as its Steam launch option.
Each time you start Battle.net from Steam, it:

1. **Checks the registry.** It makes sure all three registry files are
   complete, valid 64-bit Wine registry files.
2. **Backs it up.** If everything is fine, it saves a copy. It keeps the
   5 newest copies and skips the backup if nothing has changed since the
   last one.
3. **Repairs it.** If a file is broken, it puts back the newest good backup
   and shows a desktop notification. The broken files are kept, just in case.
4. **Starts Battle.net** as usual.

There are also commands to run by hand, for example when there is no
backup yet:

- **`--rebuild`** sets up the prefix from scratch and installs Battle.net
  again with Proton. Your Steam shortcut stays exactly as it is, and games
  installed outside the prefix are not touched.
- **`--kill`** stops a stuck Battle.net. Only processes of this prefix are
  stopped. Other running games are left alone.

It finds Steam (standard, Flatpak or Snap), your Battle.net prefix and your
Proton versions (GE-Proton and Valve's Proton) by itself, and only asks when
it has to choose.

## Requirements

- **Linux** with **Steam**, installed from the Steam website or your package
  manager, as a **Flatpak** or as a **Snap**.

  > **Note:** Flatpak and Snap support has so far only been tested in the
  > automated tests, not with a real Flatpak or Snap Steam. If something
  > doesn't work there, please
  > [open an issue](https://github.com/schaetzlein/bnet-proton-guard/issues).
- **Battle.net added to Steam as a non-Steam game**, with a Proton version
  chosen under *Properties → Compatibility → Force the use of a specific
  Steam Play compatibility tool*. Battle.net must have been installed once.
- **Bash** and the usual command line tools, which every Linux system has.
- Optional: `notify-send` for desktop notifications (preinstalled on most
  desktops).

## Install

1. Download `bnet-proton-guard` from this page (click the file, then the
   **Download raw file** button), or run:

   ```bash
   curl -LO https://raw.githubusercontent.com/schaetzlein/bnet-proton-guard/main/bnet-proton-guard
   ```

2. Run the setup:

   ```bash
   bash bnet-proton-guard --setup
   ```

   It finds your Battle.net prefix, copies the script to `~/.local/bin`,
   makes the first backup (or offers a repair if the registry is already
   broken) and shows the line for Steam:

   ```text
   Prefix:  /home/you/.local/share/Steam/steamapps/compatdata/2950000001
     OK      system.reg
     OK      user.reg
     OK      userdef.reg
   Backups: 0 in /home/you/.local/share/bnet-proton-guard/2950000001
   Backup created: /home/you/.local/share/bnet-proton-guard/2950000001/20261110-115721

   Last step – in Steam:
     Battle.net shortcut → Properties → Launch Options:

       /home/you/.local/bin/bnet-proton-guard %command%
   ```

3. In Steam, right-click the **Battle.net** shortcut → **Properties** and
   paste that line into **Launch Options**. Keep `%command%` at the end.

That's it. From now on the registry is backed up every time you start
Battle.net from Steam and repaired automatically after a crash.

## Usage

Normally you don't need to do anything: Steam runs the script for you.
For manual checks and repairs, open a terminal and run:

| Command | What it does |
|---|---|
| `bnet-proton-guard --setup` | Sets everything up (see [Install](#install)) |
| `bnet-proton-guard --check` | Checks the registry and shows how many backups there are |
| `bnet-proton-guard --backup` | Backs up the registry now |
| `bnet-proton-guard --restore` | Puts back the newest good backup |
| `bnet-proton-guard --kill` | Stops stuck processes of the prefix |
| `bnet-proton-guard --rebuild [Setup.exe]` | Sets up the prefix from scratch and installs Battle.net again |
| `bnet-proton-guard --version` | Shows the version |
| `bnet-proton-guard --help` | Shows a short help text |

A check after a crash looks like this:

```text
$ bnet-proton-guard --check
Prefix:  /home/you/.local/share/Steam/steamapps/compatdata/2950000001
  BROKEN  system.reg
  OK      user.reg
  OK      userdef.reg
Backups: 1 in /home/you/.local/share/bnet-proton-guard/2950000001

$ bnet-proton-guard --restore
Stopped 0 process(es) of this prefix.
Registry restored from /home/you/.local/share/bnet-proton-guard/2950000001/20261110-115721 (broken files kept in /home/you/.local/share/bnet-proton-guard/2950000001/broken-20261110-115721).
```

### Options for advanced use

Options go **before** the command:

| Option | What it does |
|---|---|
| `--prefix DIR` | Uses this prefix folder (`…/steamapps/compatdata/<id>`) instead of finding it |
| `--yes`, `-y` | Never asks and takes the suggested answers |

| Environment variable | What it does |
|---|---|
| `BNET_GUARD_KEEP=N` | Keeps `N` backups instead of 5 |
| `NO_COLOR=1` | Turns off colors |

Exit codes:

| Code | Meaning |
|---|---|
| 0 | Everything worked |
| 1 | Something went wrong (the message says what), or `--check` found a broken file |

As a Steam launch option the script ends with Battle.net's own exit code.

## Important: it changes the registry files of the prefix

To repair Battle.net, the script **replaces the registry files** in the
prefix (`…/compatdata/<id>/pfx/system.reg`, `user.reg`, `userdef.reg`).
To keep this safe, it:

- only replaces them when they are broken, and only with a backup that was
  checked to be valid
- keeps the broken files in a `broken-YYYYMMDD-HHMMSS` folder next to the
  backups
- never deletes the old prefix on `--rebuild`, but moves it aside to
  `…/compatdata/<id>.bak-YYYYMMDD-HHMMSS`

Where things are stored:

| Path | Content |
|---|---|
| `~/.config/bnet-proton-guard/config` | The chosen prefix |
| `~/.local/share/bnet-proton-guard/<id>/` | Registry backups and `broken-*` folders |
| `~/.local/share/bnet-proton-guard/bnet-proton-guard.log` | Log of everything the script did |

`XDG_CONFIG_HOME` and `XDG_DATA_HOME` are respected. Settings and backups from
the old name `bnet-guard` are moved over automatically.

**To undo a repair:** close Battle.net, then copy the files back from the
`broken-*` folder (or from any other backup) into the prefix:

```bash
cp ~/.local/share/bnet-proton-guard/<id>/broken-YYYYMMDD-HHMMSS/*.reg \
   ~/.local/share/Steam/steamapps/compatdata/<id>/pfx/
```

## Troubleshooting

- **Battle.net still quits right away.** Run `bnet-proton-guard --check`. If
  a file is `BROKEN`, run `bnet-proton-guard --restore`. If there is no
  valid backup, run `bnet-proton-guard --rebuild`. If everything is `OK`, the
  registry is not the cause: set the launch option to
  `PROTON_LOG=1 /home/you/.local/bin/bnet-proton-guard %command%`, start
  Battle.net once and look at `~/steam-<id>.log`.
- **My games are gone after `--rebuild`.** The games are still there, only
  Battle.net forgot about them. Start Battle.net from Steam and log in.
  Open the page of the game (not the home page), click **"Locate the game"**
  below the Install button and choose the game folder. Linux folders are on
  drive `Z:`, for example `Z:\home\you\Games\World of Warcraft`. The
  *Scan for games* dialog on the home page often finds nothing under Wine.
- **`--rebuild` can't find Battle.net-Setup.exe.** It looks for the newest
  `Battle.net-Setup*.exe` in your Downloads folder. Download it from
  <https://www.blizzard.com/download>, or give the path:
  `bnet-proton-guard --rebuild /path/to/Battle.net-Setup.exe`.
- **Which Proton does `--rebuild` use?** GE-Proton first (newest first), then
  Valve's Proton. In a terminal you can choose; with `--yes` the first one
  is used. Choose the same one that is set for Battle.net in Steam.
- **Battle.net or its installer hangs.** Run `bnet-proton-guard --kill`. It
  only stops processes of this prefix.
- **I have more than one Battle.net prefix.** `--setup` asks which one to use.
  As a launch option, the script always uses the prefix Steam starts, so
  every shortcut gets its own backups.
- **Does it work with Lutris, Heroic or plain Wine?** It is made for Steam
  with Proton. `--check`, `--backup` and `--restore` work on any prefix given
  with `--prefix`; the launch option and `--rebuild` need Steam.

## See also

- [GE-Proton Pilot](https://github.com/schaetzlein/ge-proton-pilot) keeps
  GE-Proton up to date for Steam on Linux.

## For developers: running the tests

The tests run the script in a fake environment: a temporary home folder, a
made-up Steam library with a Battle.net prefix, broken registry files and
stand-ins for Proton. They never touch your real Steam or Battle.net.

```bash
make lint   # shellcheck
make test   # bats tests in tests/
```

You need [ShellCheck](https://www.shellcheck.net/) and
[bats-core](https://github.com/bats-core/bats-core), for example
`sudo apt install shellcheck bats`. To use copies that aren't on your PATH,
set `SHELLCHECK=/path/to/shellcheck` or `BATS=/path/to/bats`. Please run
both before you open a pull request. See [CONTRIBUTING.md](CONTRIBUTING.md)
for more.

## License

[MIT](LICENSE)
