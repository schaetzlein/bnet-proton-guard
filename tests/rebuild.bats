#!/usr/bin/env bats
# --rebuild: recreate the prefix and reinstall Battle.net with Proton

load test_helper

prepare() {
  export FAKE_PROTON_LOG="$T/proton.log"
  make_proton "$STEAM/steamapps/common/Proton 10.0"
  make_proton "$STEAM/compatibilitytools.d/GE-Proton10-34"
  SETUP_EXE="$HOME/Downloads/Battle.net-Setup.exe"
  echo "MZ fake" >"$SETUP_EXE"
  echo "old prefix" >"$PFX/marker"
}

@test "--rebuild waits for all installer processes of the prefix" {
  prepare
  start=$SECONDS
  run "$GUARD" --prefix "$COMPAT" --yes --rebuild
  [ "$status" -eq 0 ]
  # the fake installer restarts itself and needs ~3 s in total
  (( SECONDS - start >= 3 ))
  [[ $output == *"Waiting for the installer to finish"* ]]
  [[ $output == *"Battle.net installed."* ]]
  [ -f "$PFX/drive_c/Program Files (x86)/Battle.net/Battle.net Launcher.exe" ]
  # nothing of the installer is still running
  [ -z "$(PFX=$PFX guard_fn prefix_pids)" ]
}

@test "--rebuild moves the old prefix aside and uses GE-Proton" {
  prepare
  run "$GUARD" --prefix "$COMPAT" --yes --rebuild
  [ "$status" -eq 0 ]
  old=$(find "$STEAM/steamapps/compatdata" -mindepth 1 -maxdepth 1 -name "$APPID.bak-*")
  [ -n "$old" ]
  [ "$(cat "$old/pfx/marker")" = "old prefix" ]
  [ ! -e "$PFX/marker" ]
  [ "$(cat "$FAKE_PROTON_LOG")" = "GE-Proton10-34 run $SETUP_EXE" ]
  [[ $output == *"Locate the game"* ]]
  [ "$(backup_count)" -eq 1 ]
}

@test "--rebuild picks the newest Battle.net-Setup*.exe from Downloads" {
  prepare
  echo "MZ newer" >"$HOME/Downloads/Battle.net-Setup (1).exe"
  touch -d '2020-01-01' "$SETUP_EXE"
  run "$GUARD" --prefix "$COMPAT" --yes --rebuild
  [ "$status" -eq 0 ]
  [ "$(cat "$FAKE_PROTON_LOG")" = "GE-Proton10-34 run $HOME/Downloads/Battle.net-Setup (1).exe" ]
}

@test "--rebuild accepts an explicit path to the setup file" {
  prepare
  rm "$SETUP_EXE"
  echo "MZ" >"$T/my-setup.exe"
  run "$GUARD" --prefix "$COMPAT" --yes --rebuild "$T/my-setup.exe"
  [ "$status" -eq 0 ]
  [ "$(cat "$FAKE_PROTON_LOG")" = "GE-Proton10-34 run $T/my-setup.exe" ]
}

@test "--rebuild stops without a setup file and leaves the prefix alone" {
  prepare
  rm "$SETUP_EXE"
  run "$GUARD" --prefix "$COMPAT" --yes --rebuild
  [ "$status" -eq 1 ]
  [[ $output == *"Battle.net-Setup.exe not found"* ]]
  [ -f "$PFX/marker" ]
}

@test "--rebuild stops when no Proton is installed" {
  echo "MZ" >"$HOME/Downloads/Battle.net-Setup.exe"
  run "$GUARD" --prefix "$COMPAT" --yes --rebuild
  [ "$status" -eq 1 ]
  [[ $output == *"No Proton found"* ]]
  [ -d "$PFX" ]
}
