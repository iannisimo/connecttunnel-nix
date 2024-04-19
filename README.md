# connecttunnel-nix
A flake porting the SonicWall Connect Tunnel vpn client to Nix

## Usage

To use it add this flake to your nixos's flake inputs:

```nix
{
  # create an input called connecttunnel-nix, and set its url to this repository
  inputs.connecttunnel-nix.url = "github:iannisimo/connecttunnel-nix";
}
```

and then enable it as follows

```nix
{
  inputs,
  ...
}: {
  imports = [ inputs.connecttunnel-nix.nixosModule ];

  programs.connect-tunnel.enable = true;
}
```