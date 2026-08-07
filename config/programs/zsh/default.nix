{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history.size = 10000;
    history.path = "$HOME/.zsh_history";
    history.ignoreAllDups = true;

    initContent = builtins.readFile ./zsh-init.sh;

    shellAliases = {
      edit = "sudo -E nvim -n";
      gitavail = "ssh-add $HOME/Documents/Важное/recovery_keys/GitHub/github_remote_keys/key";
      update = "sudo nixos-rebuild switch --flake /home/evert/nixos-configuration";
      stop = "shutdown now";
      edconf = "sudo -E nvim /home/evert/nixos-configuration/configuration.nix";
      out = "loginctl terminate-user evert";  
    };
    
    
    oh-my-zsh = {
        enable = true;
        plugins = [
          "git"                
        ];
        theme = "robbyrussell";
      };
    };

  home.sessionVariables = {
      hypr = "/home/evert/nixos-configuration/config/sessions/hyprland/";  
      programs = "/home/evert/nixos-configuration/config/programs";
      QT_QUICK_BACKEND = "software";
      LIBGL_ALWAYS_SOFTWARE = "1";
    };

}
