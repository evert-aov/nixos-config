{ config, pkgs, lib, ... }:

{
  xdg.configFile."zed/settings.json".source = ./settings.json;
  home.packages = with pkgs; [
    pyright
    ruff
  ];
}
