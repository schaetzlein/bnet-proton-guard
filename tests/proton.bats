#!/usr/bin/env bats
# Discovery and ordering of Proton builds

load test_helper

@test "GE-Proton comes first, newest version first" {
  make_proton "$STEAM/steamapps/common/Proton 9.0"
  make_proton "$STEAM/steamapps/common/Proton 10.0"
  make_proton "$STEAM/compatibilitytools.d/GE-Proton9-27"
  make_proton "$STEAM/compatibilitytools.d/GE-Proton10-4"
  make_proton "$STEAM/compatibilitytools.d/GE-Proton10-34"
  run guard_fn find_protons
  names=$(printf '%s\n' "${lines[@]}" | xargs -d '\n' -n1 basename)
  [ "$names" = "$(printf '%s\n' GE-Proton10-34 GE-Proton10-4 GE-Proton9-27 'Proton 10.0' 'Proton 9.0')" ]
}

@test "folders without an executable proton script are ignored" {
  make_proton "$STEAM/compatibilitytools.d/GE-Proton10-34"
  mkdir -p "$STEAM/compatibilitytools.d/GE-Proton11-1"
  make_proton "$STEAM/steamapps/common/Proton 9.0"
  chmod -x "$STEAM/steamapps/common/Proton 9.0/proton"
  make_proton "$STEAM/compatibilitytools.d/luxtorpeda"
  run guard_fn find_protons
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "$STEAM/compatibilitytools.d/GE-Proton10-34" ]
}

@test "Proton builds from the Flatpak Steam are found too" {
  flat="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"
  mkdir -p "$flat/steamapps"
  make_proton "$flat/compatibilitytools.d/GE-Proton10-34"
  run guard_fn find_protons
  [ "${lines[0]}" = "$flat/compatibilitytools.d/GE-Proton10-34" ]
}
