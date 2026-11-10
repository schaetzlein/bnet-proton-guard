# Shared fixtures for the bnet-proton-guard test suite.
#
# Every test runs in a throw-away fake environment below $BATS_TEST_TMPDIR:
# a temporary HOME with a fake Steam library, a Battle.net prefix, fake Proton
# builds and stubbed desktop tools. Nothing outside that directory is touched.

# Variables defined here are used by the *.bats files that load this helper.
# shellcheck disable=SC2034

GUARD="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/bnet-proton-guard"
APPID=2950000001

setup() {
  T=$(readlink -f "$BATS_TEST_TMPDIR")
  export HOME="$T/home"
  mkdir -p "$HOME/Downloads"

  # make sure nothing from the real environment leaks in
  unset XDG_CONFIG_HOME XDG_DATA_HOME WINEPREFIX \
        STEAM_COMPAT_DATA_PATH STEAM_COMPAT_CLIENT_INSTALL_PATH BNET_GUARD_KEEP
  export NO_COLOR=1

  # stubs for desktop tools
  STUBS="$T/stubs"
  mkdir -p "$STUBS"
  NOTIFY_LOG="$T/notify.log"
  cat >"$STUBS/notify-send" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"$NOTIFY_LOG"
EOF
  cat >"$STUBS/xdg-user-dir" <<EOF
#!/usr/bin/env bash
echo "$HOME/Downloads"
EOF
  chmod +x "$STUBS"/*
  export PATH="$STUBS:$PATH"

  STEAM="$HOME/.local/share/Steam"
  COMPAT="$STEAM/steamapps/compatdata/$APPID"
  PFX="$COMPAT/pfx"
  CONF_DIR="$HOME/.config/bnet-proton-guard"
  DATA_DIR="$HOME/.local/share/bnet-proton-guard"
  BACKUP_DIR="$DATA_DIR/$APPID"
  make_prefix "$COMPAT"
}

teardown() {
  # kill anything a test left running (fake prefixes or marked with BPG_TEST)
  local p
  for p in /proc/[0-9]*; do
    [[ -O $p ]] || continue
    { tr '\0' '\n' <"$p/environ"; } 2>/dev/null |
      grep -q -e "^WINEPREFIX=$T/" -e "^BPG_TEST=$T\$" &&
      kill -9 "${p#/proc/}" 2>/dev/null
  done
  return 0
}

# ---------- registry fixtures --------------------------------------------------

# good_reg FILE [MARKER] – write a minimal valid 64-bit Wine registry file
good_reg() {
  printf 'WINE REGISTRY Version 2\n;; All keys relative to \\\\Machine\n\n#arch=win64\n\n[Software\\\\Test] 1700000000\n"Marker"="%s"\n' \
    "${2:-default}" >"$1"
}

# nullbyte_reg FILE – what a crash typically leaves behind
nullbyte_reg() { head -c 8192 /dev/zero >"$1"; }

make_prefix() {  # make_prefix COMPATDIR – Battle.net prefix with a healthy registry
  local c=$1 r
  mkdir -p "$c/pfx/drive_c/Program Files (x86)/Battle.net"
  touch "$c/pfx/drive_c/Program Files (x86)/Battle.net/Battle.net Launcher.exe"
  for r in system.reg user.reg userdef.reg; do good_reg "$c/pfx/$r" "$r"; done
}

# make_backup NAME [MARKER] – pre-existing good backup in the backup folder
make_backup() {
  local d="$BACKUP_DIR/$1" r
  mkdir -p "$d"
  for r in system.reg user.reg userdef.reg; do good_reg "$d/$r" "${2:-$1}"; done
}

backup_count() { find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d -name '20*' | wc -l; }

# ---------- Proton fixtures ----------------------------------------------------

# make_proton DIR – fake Proton build. "proton run X" records the call and then
# behaves like the Battle.net installer: it detaches, restarts itself once and
# only creates "Battle.net Launcher.exe" a few seconds later. Like real Proton
# it exports WINEPREFIX with a trailing slash.
make_proton() {
  local d=$1
  mkdir -p "$d"
  cat >"$d/proton" <<'EOF'
#!/usr/bin/env bash
echo "$(basename "$(dirname "$0")") $*" >>"$FAKE_PROTON_LOG"
[[ $1 == run ]] || exit 0
WINEPREFIX="$STEAM_COMPAT_DATA_PATH/pfx/" "$(dirname "$0")/fake-installer" 1 >/dev/null 2>&1 &
exit 0
EOF
  cat >"$d/fake-installer" <<'EOF'
#!/usr/bin/env bash
# stage 1 restarts itself (like the real Battle.net installer), stage 2 installs
if [[ $1 == 1 ]]; then
  sleep 1
  "$0" 2 >/dev/null 2>&1 &
  exit 0
fi
sleep 2
bnet="${WINEPREFIX}drive_c/Program Files (x86)/Battle.net"
mkdir -p "$bnet"
for r in system.reg user.reg userdef.reg; do
  printf 'WINE REGISTRY Version 2\n\n#arch=win64\n' >"${WINEPREFIX}$r"
done
touch "$bnet/Battle.net Launcher.exe"
EOF
  chmod +x "$d/proton" "$d/fake-installer"
}

# run a function of the guard without its main part, e.g. `guard_fn find_protons`.
# Variables the function needs (like PFX) can be passed in the environment.
guard_fn() {
  bash -c 'source <(sed "/^# ---------- main/,\$d" "$1"); shift; "$@"' _ "$GUARD" "$@"
}
