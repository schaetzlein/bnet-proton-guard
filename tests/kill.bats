#!/usr/bin/env bats
# --kill must only hit processes whose WINEPREFIX is this prefix

load test_helper

spawn() {   # spawn [VAR=value…] – start a long sleep with this environment, print its PID
  env BPG_TEST="$T" "$@" sleep 300 >/dev/null 2>&1 3>&- &
  echo $!
}

alive() {   # process exists and is not a zombie
  [[ -e /proc/$1 && $(awk '{print $3}' "/proc/$1/stat" 2>/dev/null) != Z ]]
}

@test "--kill stops only processes of this prefix" {
  proton_style=$(spawn WINEPREFIX="$PFX/")
  wine_style=$(spawn WINEPREFIX="$PFX")
  other_prefix=$(spawn WINEPREFIX="$STEAM/steamapps/compatdata/2950000002/pfx/")
  similar_name=$(spawn WINEPREFIX="${PFX}2/")
  no_prefix=$(spawn FOO=bar)
  sleep 0.3

  run "$GUARD" --prefix "$COMPAT" --kill
  [ "$status" -eq 0 ]
  [[ $output == *"Stopped 2 process(es)"* ]]
  sleep 0.3

  run alive "$proton_style"; [ "$status" -ne 0 ]
  run alive "$wine_style";   [ "$status" -ne 0 ]
  alive "$other_prefix"
  alive "$similar_name"
  alive "$no_prefix"
}

@test "--kill reports zero when nothing runs in the prefix" {
  run "$GUARD" --prefix "$COMPAT" --kill
  [ "$status" -eq 0 ]
  [[ $output == *"Stopped 0 process(es)"* ]]
}
