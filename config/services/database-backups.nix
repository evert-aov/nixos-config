{ config, pkgs, ... }:
let
  backup = pkgs.writeShellApplication {
    name = "database-backup";
    runtimeInputs = [
      pkgs.python3
      pkgs.util-linux
      config.services.postgresql.package
      pkgs.mongodb-tools
      pkgs.mongosh
    ];
    text = ''
      exec python3 ${./database_backup.py} "$@"
    '';
  };
in
{
  environment.systemPackages = [ backup ];

  systemd.services.database-backup = {
    description = "Respaldos lógicos de PostgreSQL y MongoDB";
    requires = [ "postgresql.service" "mongodb.service" ];
    after = [ "postgresql.service" "mongodb.service" ];
    unitConfig.RequiresMountsFor = [ "/mnt/datos" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      UMask = "0077";
      ExecStart = "${backup}/bin/database-backup create --destination /mnt/datos/backups/databases --mount /mnt/datos --retention-days 14";
      Nice = 10;
      IOSchedulingClass = "best-effort";
      IOSchedulingPriority = 7;
      CPUWeight = 20;
      IOWeight = 20;
      TimeoutStartSec = "2h";
    };
  };
  systemd.timers.database-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 04:00:00";
      RandomizedDelaySec = "20m";
      Persistent = true;
    };
  };
}
