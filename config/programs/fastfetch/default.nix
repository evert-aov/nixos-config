{ config, lib, ... }:

let
  files = builtins.readDir ./.;
  jsoncFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".jsonc" name) files;
in
{
  xdg.configFile = lib.mapAttrs' (name: _: lib.nameValuePair "fastfetch/${name}" { source = ./${name}; }) jsoncFiles;
}
