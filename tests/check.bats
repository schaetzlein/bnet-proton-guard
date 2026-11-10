#!/usr/bin/env bats
# Detection of broken registry files (--check)

load test_helper

@test "--check reports a healthy registry" {
  run "$GUARD" --prefix "$COMPAT" --check
  [ "$status" -eq 0 ]
  [[ $output == *"OK      system.reg"* ]]
  [[ $output == *"OK      user.reg"* ]]
  [[ $output == *"OK      userdef.reg"* ]]
}

@test "--check detects a system.reg full of null bytes" {
  nullbyte_reg "$PFX/system.reg"
  run "$GUARD" --prefix "$COMPAT" --check
  [ "$status" -eq 1 ]
  [[ $output == *"BROKEN  system.reg"* ]]
  [[ $output == *"OK      user.reg"* ]]
}

@test "--check detects an empty registry file" {
  : >"$PFX/user.reg"
  run "$GUARD" --prefix "$COMPAT" --check
  [ "$status" -eq 1 ]
  [[ $output == *"BROKEN  user.reg"* ]]
}

@test "--check detects a missing registry file" {
  rm "$PFX/userdef.reg"
  run "$GUARD" --prefix "$COMPAT" --check
  [ "$status" -eq 1 ]
  [[ $output == *"BROKEN  userdef.reg"* ]]
}

@test "--check detects a wrong header" {
  printf 'garbage\n#arch=win64\n' >"$PFX/system.reg"
  run "$GUARD" --prefix "$COMPAT" --check
  [ "$status" -eq 1 ]
  [[ $output == *"BROKEN  system.reg"* ]]
}

@test "--check detects a registry that lost its 64-bit marker" {
  printf 'WINE REGISTRY Version 2\n\n[Software] 1\n' >"$PFX/system.reg"
  run "$GUARD" --prefix "$COMPAT" --check
  [ "$status" -eq 1 ]
  [[ $output == *"BROKEN  system.reg"* ]]
}

@test "--check accepts CRLF line endings in the header" {
  printf 'WINE REGISTRY Version 2\r\n\r\n#arch=win64\r\n' >"$PFX/system.reg"
  run "$GUARD" --prefix "$COMPAT" --check
  [ "$status" -eq 0 ]
}

@test "--check finds the prefix by itself when none is configured" {
  run "$GUARD" --check
  [ "$status" -eq 0 ]
  [[ $output == *"Prefix:  $COMPAT"* ]]
}

@test "--check uses the prefix from the config file" {
  other="$STEAM/steamapps/compatdata/2950000002"
  make_prefix "$other"
  mkdir -p "$CONF_DIR"
  printf 'BNET_PREFIX=%q\n' "$other" >"$CONF_DIR/config"
  run "$GUARD" --check
  [ "$status" -eq 0 ]
  [[ $output == *"Prefix:  $other"* ]]
}

@test "--check fails cleanly when no Battle.net prefix exists" {
  rm -rf "$STEAM/steamapps/compatdata"
  mkdir -p "$STEAM/steamapps/compatdata"
  run "$GUARD" --check
  [ "$status" -eq 1 ]
  [[ $output == *"No Battle.net prefix found"* ]]
}
