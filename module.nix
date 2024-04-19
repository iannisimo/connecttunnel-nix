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
  };
  
  config = lib.mkIf cfg.enable ({

    environment.systemPackages = [ ct-pkg ];

    security.wrappers."AvConnect" = {
      setuid = true;
      owner = "root";
      group = "root";
      source = "${ct-pkg}/usr/local/Aventail/AvConnect";
    };

  });
}