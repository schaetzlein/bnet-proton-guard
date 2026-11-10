#!/usr/bin/env bats
# Backups (--backup), rotation and manual restore (--restore)

load test_helper

@test "--backup copies all three registry files" {
  run "$GUARD" --prefix "$COMPAT" --backup
  [ "$status" -eq 0 ]
  [ "$(backup_count)" -eq 1 ]
  b=$(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -name '20*')
  for r in system.reg user.reg userdef.reg; do cmp "$PFX/$r" "$b/$r"; done
}

@test "--backup skips an unchanged registry" {
  make_backup 20250101-000000
  for r in system.reg user.reg userdef.reg; do cp "$BACKUP_DIR/20250101-000000/$r" "$PFX/$r"; done
  run "$GUARD" --prefix "$COMPAT" --backup
  [ "$status" -eq 0 ]
  [ "$(backup_count)" -eq 1 ]
  [[ $output != *"Backup created"* ]]
}

@test "--backup creates a new backup when the registry changed" {
  make_backup 20250101-000000 old
  run "$GUARD" --prefix "$COMPAT" --backup
  [ "$status" -eq 0 ]
  [ "$(backup_count)" -eq 2 ]
  [[ $output == *"Backup created"* ]]
}

@test "--backup keeps only the newest 5 backups" {
  for i in 1 2 3 4 5; do make_backup "2025010$i-000000"; done
  run "$GUARD" --prefix "$COMPAT" --backup
  [ "$status" -eq 0 ]
  [ "$(backup_count)" -eq 5 ]
  [ ! -e "$BACKUP_DIR/20250101-000000" ]
  [ -d "$BACKUP_DIR/20250102-000000" ]
}

@test "BNET_GUARD_KEEP changes the number of kept backups" {
  for i in 1 2 3 4 5; do make_backup "2025010$i-000000"; done
  BNET_GUARD_KEEP=2 run "$GUARD" --prefix "$COMPAT" --backup
  [ "$status" -eq 0 ]
  [ "$(backup_count)" -eq 2 ]
  [ -d "$BACKUP_DIR/20250105-000000" ]
}

@test "--backup refuses to back up a broken registry" {
  nullbyte_reg "$PFX/system.reg"
  run "$GUARD" --prefix "$COMPAT" --backup
  [ "$status" -eq 1 ]
  [[ $output == *"no backup made"* ]]
  [ "$(backup_count)" -eq 0 ]
}

@test "--restore puts back the newest good backup and keeps the broken files" {
  make_backup 20250101-000000 older
  make_backup 20250102-000000 newest
  nullbyte_reg "$PFX/system.reg"
  run "$GUARD" --prefix "$COMPAT" --restore
  [ "$status" -eq 0 ]
  cmp "$BACKUP_DIR/20250102-000000/system.reg" "$PFX/system.reg"
  broken=$(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -name 'broken-*')
  [ -n "$broken" ]
  cmp <(head -c 8192 /dev/zero) "$broken/system.reg"
}

@test "--restore skips backups that are broken themselves" {
  make_backup 20250101-000000 good
  make_backup 20250102-000000 bad
  nullbyte_reg "$BACKUP_DIR/20250102-000000/user.reg"
  nullbyte_reg "$PFX/system.reg"
  run "$GUARD" --prefix "$COMPAT" --restore
  [ "$status" -eq 0 ]
  cmp "$BACKUP_DIR/20250101-000000/system.reg" "$PFX/system.reg"
}

@test "--restore fails without a valid backup" {
  nullbyte_reg "$PFX/system.reg"
  run "$GUARD" --prefix "$COMPAT" --restore
  [ "$status" -eq 1 ]
  [[ $output == *"No valid backup available"* ]]
}
