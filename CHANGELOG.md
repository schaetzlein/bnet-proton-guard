# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- README rewritten to be easier to follow for beginners, with example output,
  a section on which files the script changes and how to undo a repair.

### Removed

- GitHub Actions CI and the status badges. Run `make lint test` locally instead.

## [1.0] - 2026-11-10

First public release.

### Added

- Steam launch option mode (`bnet-proton-guard %command%`): checks the Wine registry of
  the Battle.net prefix on every launch, backs it up when it is healthy (the last 5
  states, unchanged states are skipped) and restores the newest good backup when it is
  broken, with a desktop notification.
- `--setup`: finds the Battle.net prefix, installs the script to `~/.local/bin`, makes
  the first backup or offers a repair, and prints the Steam launch option.
- `--check`, `--backup` and `--restore` for manual use.
- `--kill`: stops stuck processes of this prefix only (matched by `WINEPREFIX`).
- `--rebuild`: recreates the prefix and reinstalls Battle.net with Proton, waits for
  the self-restarting installer and explains how to add installed games again via
  "Locate the game" and drive `Z:`.
- Detection of native, Flatpak and Snap Steam, of Battle.net prefixes and of Proton
  builds (GE-Proton first, newest first).
- Automatic migration of settings and backups from the pre-release name `bnet-guard`.
- Test suite (bats-core) with a fake Steam library, Battle.net prefix and Proton builds.
- GitHub Actions CI running ShellCheck and the tests.

[Unreleased]: https://github.com/schaetzlein/bnet-proton-guard/compare/v1.0...HEAD
[1.0]: https://github.com/schaetzlein/bnet-proton-guard/releases/tag/v1.0
