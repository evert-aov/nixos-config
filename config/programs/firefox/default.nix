{ config, pkgs, ... }:

let
  profileDir = ".mozilla/firefox/js2u246a.default";
in
{
  home.file."${profileDir}/chrome/userChrome.css".source = ./userChrome.css;
  home.file."${profileDir}/chrome/userContent.css".source = ./userContent.css;
  home.file."${profileDir}/user.js".source = ./user.js;
}
