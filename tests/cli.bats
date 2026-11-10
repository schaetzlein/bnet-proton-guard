#!/usr/bin/env bats
# Command line handling and --setup

load test_helper

@test "--version prints the version" {
  run "$GUARD" --version
  [ "$status" -eq 0 ]
  [[ $output =~ ^bnet-proton-guard\ [0-9]+\.[0-9]+$ ]]
}

@test "--help and no arguments print the usage" {
  run "$GUARD" --help
  [ "$status" -eq 0 ]
  [[ $output == *"Steam launch option"* ]]
  run "$GUARD"
  [ "$status" -eq 0 ]
  [[ $output == *"--rebuild"* ]]
}

@test "--prefix without a value fails instead of hanging" {
  run timeout 5 "$GUARD" --prefix
  [ "$status" -eq 1 ]
  [[ $output == *"--prefix needs a directory"* ]]
}

@test "--prefix=DIR works as well" {
  run "$GUARD" --prefix="$COMPAT/" --check
  [ "$status" -eq 0 ]
  [[ $output == *"Prefix:  $COMPAT"$'\n'* ]]
}

@test "--setup saves the prefix, installs the script and makes a backup" {
  run "$GUARD" --yes --setup
  [ "$status" -eq 0 ]
  [ -x "$HOME/.local/bin/bnet-proton-guard" ]
  cmp "$GUARD" "$HOME/.local/bin/bnet-proton-guard"
  # shellcheck source=/dev/null
  (. "$CONF_DIR/config"; [ "$BNET_PREFIX" = "$COMPAT" ])
  [ "$(backup_count)" -eq 1 ]
  [[ $output == *"$HOME/.local/bin/bnet-proton-guard %command%"* ]]
}

@test "--setup offers to restore a broken registry" {
  make_backup 20250101-000000 good
  nullbyte_reg "$PFX/system.reg"
  run "$GUARD" --yes --setup
  [ "$status" -eq 0 ]
  [[ $output == *"Registry restored"* ]]
  cmp "$BACKUP_DIR/20250101-000000/system.reg" "$PFX/system.reg"
}
