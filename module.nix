{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.programs.connect-tunnel;
  ct-pkg = pkgs.callPackage ./connect-tunnel.nix { };
in {
  options.programs.connect-tunnel = {
    enable = lib.mkEnableOption "Connect Tunnel VPN client";

    enableService = lib.mkEnableOption "Enable the Connect Tunnel VPN client service";

    configFile = lib.mkOption {
      default = "/etc/aventail/aventailconnect";
      type = lib.types.str;
      description = "Path to the configuration file";
    };
  };
  
  config = (lib.mkIf cfg.enable {

    environment.systemPackages = [ ct-pkg ];

    security.wrappers."AvConnect" = {
      setuid = true;
      owner = "root";
      group = "root";
      source = "${ct-pkg}/usr/local/Aventail/AvConnect";
    };

  }) // (lib.mkIf cfg.enableService {
    systemd.services.connect-tunnel = {
      description = "Connect Tunnel VPN client";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      preStart = "mkdir -p /root/.sonicwall/AventailConnect/config/ && cp ${cfg.configFile} /root/.sonicwall/AventailConnect/config/profiles.xml";
      preStop = "rm /root/.sonicwall/AventailConnect/config/profiles.xml";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${ct-pkg}/bin/startct -m console";
        Restart = "Always";
        User = "root";
        Group = "root";
      };
    };
  });
}