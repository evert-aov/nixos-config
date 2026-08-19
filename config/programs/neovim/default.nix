{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraPackages = with pkgs; [
      # General
      ripgrep
      fd
      nodejs # servidor de markdown-preview.nvim

      # LSP Servers para tu stack
      lua-language-server
      pyright # Python
      nil # Nix
      nixpkgs-fmt

      # C/C++ (clangd) y QML (qmlls)
      clang-tools
      qt6.qtdeclarative

      # Java/Kotlin (Spring Boot)
      jdt-language-server
      kotlin-language-server

      # Dart/Flutter
      dart-sass
      flutter

      # JavaScript/TypeScript (Angular)
      typescript-language-server
      angular-language-server
      eslint
      prettier

      # PostgreSQL
      sqls # SQL LSP

      # Formateadores adicionales
      black # Python
      isort # Python
      pylint # Python linter
      google-java-format # Java
      prettierd # JS/TS/HTML/CSS

      # Linters
      shellcheck
      markdownlint-cli
    ];

    plugins = with pkgs.vimPlugins; [
      # Temas
      catppuccin-nvim
      nvim-web-devicons

      # Treesitter (syntax highlighting mejorado)
      (nvim-treesitter.withAllGrammars)

      # UI
      lualine-nvim
      bufferline-nvim
      indent-blankline-nvim
      gitsigns-nvim
      which-key-nvim
      nvim-tree-lua

      # Herramientas de desarrollo
      plenary-nvim
      telescope-nvim
      telescope-ui-select-nvim
      nvim-autopairs
      comment-nvim

      # LSP y Autocompletado
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-cmdline
      luasnip
      cmp_luasnip
      friendly-snippets
      rainbow-delimiters-nvim

      # Extensiones específicas para tu stack
      vim-javacomplete2 # Java completions
      vim-dadbod # Base de datos
      vim-dadbod-ui # UI para base de datos
      vim-dadbod-completion # Completado SQL
      none-ls-nvim # Formateo y linting (fork de null-ls)
      nvim-dap # Debugging
      nvim-dap-ui # UI para debugging
      nvim-dap-virtual-text # Virtual text para debugging
      nvim-treesitter-context # Contexto visual
      trouble-nvim # Mejor visualización de diagnostics
      markdown-preview-nvim # Preview de markdown en el navegador
    ];
  };

  xdg.configFile."nvim/init.lua".source = ./nvim/init.lua;
}
