{ config, pkgs, lib, ... }:

{
  xdg.configFile."zed/settings.json".source = ./settings.json;
}
