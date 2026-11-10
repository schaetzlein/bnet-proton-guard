#!/usr/bin/env bats
# Wrapper mode: "bnet-proton-guard %command%" as Steam launch option

load test_helper

make_game() {   # fake %command% that records its arguments
  GAME="$T/stubs/fake-game"
  GAME_LOG="$T/game.log"
  cat >"$GAME" <<EOF2
#!/usr/bin/env bash
printf '<%s>' "\$@" >"$GAME_LOG"
exit 42
EOF2
  chmod +x "$GAME"
}

@test "wrapper backs up a healthy registry and runs the command" {
  make_game
  STEAM_COMPAT_DATA_PATH=$COMPAT run "$GUARD" "$GAME" waitforexitandrun "arg with spaces"
  [ "$status" -eq 42 ]
  [ "$(cat "$GAME_LOG")" = "<waitforexitandrun><arg with spaces>" ]
  [ "$(backup_count)" -eq 1 ]
}

@test "wrapper restores a broken registry automatically" {
  make_game
  make_backup 20250101-000000 good
  nullbyte_reg "$PFX/system.reg"
  STEAM_COMPAT_DATA_PATH=$COMPAT run "$GUARD" "$GAME"
  [ "$status" -eq 42 ]
  cmp "$BACKUP_DIR/20250101-000000/system.reg" "$PFX/system.reg"
  [ -n "$(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -name 'broken-*')" ]
  grep -q "has been restored" "$NOTIFY_LOG"
  [ -f "$GAME_LOG" ]
}

@test "wrapper still starts the command when no backup exists" {
  make_game
  nullbyte_reg "$PFX/system.reg"
  STEAM_COMPAT_DATA_PATH=$COMPAT run "$GUARD" "$GAME"
  [ "$status" -eq 42 ]
  grep -q "there is no backup" "$NOTIFY_LOG"
  [ -f "$GAME_LOG" ]
}

@test "wrapper uses the configured prefix when Steam does not set one" {
  make_game
  mkdir -p "$CONF_DIR"
  printf 'BNET_PREFIX=%q\n' "$COMPAT" >"$CONF_DIR/config"
  run "$GUARD" "$GAME"
  [ "$status" -eq 42 ]
  [ "$(backup_count)" -eq 1 ]
}

@test "wrapper just runs the command when no prefix is known" {
  make_game
  run "$GUARD" "$GAME" x
  [ "$status" -eq 42 ]
  [ "$(cat "$GAME_LOG")" = "<x>" ]
  [ ! -d "$BACKUP_DIR" ]
}

@test "wrapper does nothing to a prefix that has not been initialised yet" {
  make_game
  rm "$PFX"/*.reg
  STEAM_COMPAT_DATA_PATH=$COMPAT run "$GUARD" "$GAME"
  [ "$status" -eq 42 ]
  [ "$(backup_count)" -eq 0 ]
  [ ! -e "$NOTIFY_LOG" ]
}
