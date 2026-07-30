{ config, pkgs, lib, ... }:

{ 
  xdg.configFile."matugen".source = ./matugen;
}
