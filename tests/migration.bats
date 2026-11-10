#!/usr/bin/env bats
# Migration of settings and backups from the old name "bnet-guard"

load test_helper

@test "old bnet-guard folders are moved to the new name" {
  mkdir -p "$HOME/.config/bnet-guard" "$HOME/.local/share/bnet-guard/$APPID/20250101-000000"
  echo "BNET_PREFIX=$COMPAT" >"$HOME/.config/bnet-guard/config"
  run "$GUARD" --version
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.config/bnet-guard" ]
  [ ! -e "$HOME/.local/share/bnet-guard" ]
  [ -f "$CONF_DIR/config" ]
  [ -d "$BACKUP_DIR/20250101-000000" ]
}

@test "existing new folders are never overwritten" {
  mkdir -p "$HOME/.config/bnet-guard" "$CONF_DIR"
  echo old >"$HOME/.config/bnet-guard/config"
  echo new >"$CONF_DIR/config"
  run "$GUARD" --version
  [ "$status" -eq 0 ]
  [ "$(cat "$CONF_DIR/config")" = new ]
  [ "$(cat "$HOME/.config/bnet-guard/config")" = old ]
}

@test "migration honours XDG_CONFIG_HOME and XDG_DATA_HOME" {
  export XDG_CONFIG_HOME="$T/xdg-config" XDG_DATA_HOME="$T/xdg-data"
  mkdir -p "$XDG_CONFIG_HOME/bnet-guard" "$XDG_DATA_HOME/bnet-guard"
  run "$GUARD" --version
  [ "$status" -eq 0 ]
  [ -d "$XDG_CONFIG_HOME/bnet-proton-guard" ]
  [ -d "$XDG_DATA_HOME/bnet-proton-guard" ]
  [ ! -e "$XDG_DATA_HOME/bnet-guard" ]
}
