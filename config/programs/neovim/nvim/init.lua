-- ============================================
-- CONFIGURACIÓN BASE
-- ============================================
local undodir = vim.fn.stdpath("state") .. "/undo"
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end
vim.opt.undodir = undodir
vim.opt.undofile = true

-- Opciones de editor
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.clipboard = 'unnamedplus'
vim.opt.breakindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true
vim.opt.signcolumn = 'yes'
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- ============================================
-- TEMA DINÁMICO
-- ============================================
_G.reload_matugen_colors = function()
  vim.schedule(function()
    local matugen_path = vim.fn.stdpath("config") .. "/matugen_colors.lua"
    local overrides = {}

    if vim.fn.filereadable(matugen_path) == 1 then
      local chunk = loadfile(matugen_path)
      if chunk then
        local colors = chunk()
        if type(colors) == "table" then
          overrides = { all = colors, mocha = colors }
        end
      end
    end

    for k, _ in pairs(package.loaded) do
      if k:match("^catppuccin") then
        package.loaded[k] = nil
      end
    end

    vim.cmd("hi clear")
    if vim.fn.exists("syntax_on") then
      vim.cmd("syntax reset")
    end
    vim.g.colors_name = nil

    require("catppuccin").setup({
      flavour = "mocha",
      compile = { enabled = false },
      color_overrides = overrides,
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        bufferline = true,
        telescope = { enabled = true },
        indent_blankline = { enabled = true },
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
      },
    })

    vim.cmd("colorscheme catppuccin")

    local ok_lualine, lualine = pcall(require, "lualine")
    if ok_lualine then
      lualine.setup { options = { theme = 'catppuccin' } }
    end

    vim.cmd("redraw!")
    vim.notify("Matugen colors reloaded!", vim.log.levels.INFO)
  end)
end

_G.reload_matugen_colors()

-- ============================================
-- CONFIGURACIÓN DE PLUGINS
-- ============================================

-- Treesitter
require('nvim-treesitter.config').setup {
  ensure_installed = {
    "java", "kotlin", "dart", "javascript", "typescript",
    "html", "css", "json", "yaml", "xml", "sql",
    "python", "lua", "nix", "bash", "dockerfile"
  },
  highlight = { enable = true },
  indent = { enable = true },
  context_commentstring = { enable = true },
}

-- Indent Blankline
require("ibl").setup()

-- Gitsigns
require('gitsigns').setup({
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
})

-- Autopairs
require('nvim-autopairs').setup({
  check_ts = true,
  ts_config = {
    java = { "string", "comment" },
    javascript = { "string", "template_string" },
    typescript = { "string", "template_string" },
  },
})

-- Comment
require('Comment').setup()

-- Which Key
require('which-key').setup()

-- Nvim Tree
require("nvim-tree").setup({
  filters = { dotfiles = false },
  view = {
    width = 30,
    side = "left",
    preserve_window_proportions = true,
  },
  renderer = {
    highlight_git = true,
    icons = {
      show = {
        git = true,
        file = true,
        folder = true,
        folder_arrow = true,
      },
    },
  },
  actions = {
    open_file = {
      quit_on_open = false,
      resize_window = true,
      window_picker = {
        enable = true,
        chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
        exclude = {
          filetype = { "NvimTree" },
        },
      },
    },
  },
})

-- Telescope
local telescope = require('telescope')
telescope.setup {
  extensions = {
    ["ui-select"] = { require("telescope.themes").get_dropdown {} }
  },
  defaults = {
    file_ignore_patterns = {
      "node_modules", ".git", "build", "dist", "target",
      "flutter/bin", ".dart_tool", "pubspec.lock"
    },
  }
}
pcall(telescope.load_extension, 'ui-select')

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find Files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live Grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find Buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Find Help' })

-- Bufferline
require("bufferline").setup {
  options = {
    mode = "buffers",
    diagnostics = "nvim_lsp",
    separator_style = "slant",
    offsets = {
      {
        filetype = "NvimTree",
        text = "File Explorer",
        text_align = "left",
        separator = true
      }
    },
    always_show_bufferline = true,
    indicator = {
      style = "icon",
    },
  }
}

-- ============================================
-- AUTOCOMPLETADO (nvim-cmp)
-- ============================================
local cmp = require 'cmp'
local luasnip = require 'luasnip'

require("luasnip.loaders.from_vscode").lazy_load()
require("luasnip.loaders.from_vscode").lazy_load({ paths = { "./snippets" } })

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'buffer' },
    { name = 'path' },
    { name = 'dadbod' },
  },
}

-- Realtado de {[()]}
require('rainbow-delimiters.setup').setup {
  strategy = {
    [''] = require('rainbow-delimiters.strategy').global,
  },
  query = {
    [''] = 'rainbow-delimiters',
  },
  highlight = {
    'RainbowDelimiterRed',
    'RainbowDelimiterYellow',
    'RainbowDelimiterBlue',
    'RainbowDelimiterOrange',
    'RainbowDelimiterGreen',
    'RainbowDelimiterViolet',
    'RainbowDelimiterCyan',
  },
}

-- ============================================
-- LSP CONFIGURACIÓN (nvim 0.11+ / lspconfig 2.x)
-- ============================================
local capabilities = require('cmp_nvim_lsp').default_capabilities()
capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true
}

require('lspconfig')

local function setup_server(server_name, config)
  config = config or {}
  config.capabilities = vim.tbl_deep_extend("force", capabilities, config.capabilities or {})
  pcall(vim.lsp.config, server_name, config)
  pcall(vim.lsp.enable, server_name)
end

-- Configurar cada LSP
setup_server("pyright", {}) -- Python

setup_server("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      globals = { 'vim' },
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  }
})

setup_server("nil_ls", {}) -- Nix

-- Java (Spring Boot)
setup_server("jdtls", {
  settings = {
    java = {
      configuration = {
        updateBuildConfiguration = "automatic",
        runtimes = {
          {
            name = "JavaSE-17",
            path = "/usr/lib/jvm/java-17-openjdk",
          },
        },
      },
      format = {
        enabled = true,
        settings = {
          url = "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml",
          profile = "GoogleStyle",
        },
      },
      completion = {
        favoriteStaticMembers = {
          "org.hamcrest.MatcherAssert.assertThat",
          "org.hamcrest.Matchers.*",
          "org.junit.Assert.*",
          "org.junit.Assume.*",
          "org.junit.jupiter.api.Assertions.*",
          "org.mockito.Mockito.*",
        },
      },
    },
  },
})

-- Kotlin
setup_server("kotlin_language_server", {})

-- Dart/Flutter
setup_server("dartls", {
  filetypes = { "dart" },
  init_options = {
    closingLabels = true,
    dart = {
      enableSdkFormatter = true,
      enableServerConfirm = true,
    },
    flutter = {
      enableSdkFormatter = true,
      outline = true,
      widgets = true,
    },
  },
  settings = {
    dart = {
      completeFunctionCalls = true,
      enableSdkFormatter = true,
      suggestFromUnimportedLibraries = true,
    },
  },
})

-- JavaScript/TypeScript (Angular)
setup_server("ts_ls", {
  filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
  init_options = {
    plugins = {
      {
        name = "@angular/language-server",
        location = "/usr/lib/node_modules/@angular/language-server",
        languages = { "angular", "typescript", "html" },
      },
    },
  },
  settings = {
    typescript = {
      inlayHints = {
        parameterNames = { enabled = "all" },
        variableTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        enumMemberValues = { enabled = true },
      },
    },
  },
})

-- HTML (para Angular templates)
setup_server("html", {
  filetypes = { "html", "markdown" },
  init_options = {
    provideFormatter = true,
    embeddedLanguages = {
      css = true,
      javascript = true,
    },
  },
})

-- CSS
setup_server("cssls", {
  filetypes = { "css", "scss", "less" },
})

-- SQL (PostgreSQL)
setup_server("sqls", {
  filetypes = { "sql" },
  settings = {
    sqls = {
      connections = {
        {
          driver = "postgresql",
          dataSourceName = "host=localhost port=5432 user=postgres password=postgres dbname=postgres sslmode=disable",
        },
      },
    },
  },
})

-- ============================================
-- NULL-LS (Formateo y Linting)
-- ============================================
local null_ls = require("null-ls")
null_ls.setup({
  sources = {
    -- Python
    null_ls.builtins.formatting.black,
    null_ls.builtins.formatting.isort,
    null_ls.builtins.diagnostics.pylint,

    -- Java
    null_ls.builtins.formatting.google_java_format,

    -- JavaScript/TypeScript
    null_ls.builtins.formatting.prettierd,

    -- Dart
    null_ls.builtins.formatting.dart_format,

    -- SQL
    null_ls.builtins.formatting.sql_formatter,

    -- Nix
    null_ls.builtins.formatting.nixpkgs_fmt,

    -- Markdown
    null_ls.builtins.diagnostics.markdownlint,
  },
})

-- Formateo automático
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function(args)
    vim.lsp.buf.format({ bufnr = args.buf })
  end,
})

-- ============================================
-- DEBUGGING (nvim-dap)
-- ============================================
local dap = require("dap")

dap.configurations.java = {
  {
    type = "java",
    request = "launch",
    name = "Debug (Spring Boot)",
    mainClass = "org.springframework.boot.loader.JarLauncher",
    classPaths = { "${workspaceFolder}/target/classes" },
    sourcePaths = { "${workspaceFolder}/src/main/java" },
    projectName = "spring-boot-app",
    console = "integratedTerminal",
    stopOnEntry = false,
    vmArgs = "-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n",
  },
}

dap.configurations.python = {
  {
    type = "python",
    request = "launch",
    name = "Debug (FastAPI)",
    program = "${file}",
    console = "integratedTerminal",
    justMyCode = false,
    env = {
      PYTHONPATH = "${workspaceFolder}",
    },
  },
}

dap.configurations.dart = {
  {
    type = "dart",
    request = "launch",
    name = "Debug Flutter",
    program = "${workspaceFolder}/lib/main.dart",
    args = { "--debug" },
    cwd = "${workspaceFolder}",
    flutterMode = "debug",
  },
}

-- ============================================
-- TROUBLE (Mejor visualización de diagnostics)
-- ============================================
require("trouble").setup({
  position = "bottom",
  height = 10,
  icons = true,
  mode = "diagnostics",
  severity = nil,
  group = true,
  padding = true,
  action_keys = {
    close = "q",
    cancel = "<esc>",
    refresh = "r",
    jump = { "<cr>", "<tab>" },
    open_split = { "<c-x>" },
    open_vsplit = { "<c-v>" },
    open_tab = { "<c-t>" },
    jump_close = { "o" },
    toggle_mode = "m",
    toggle_preview = "P",
    toggle_auto_preview = "A",
    toggle_severity = "s",
    toggle_group = "g",
    toggle_sort = "S",
    next = "j",
    prev = "k",
    go_back = "b",
  },
})

-- ============================================
-- FILE WATCHER para recarga de tema
-- ============================================
local uv = vim.uv or vim.loop
local matugen_path = vim.fn.stdpath("config") .. "/matugen_colors.lua"

local watcher = uv.new_fs_event()
local reload_timer = nil

watcher:start(matugen_path, {}, vim.schedule_wrap(function(err, filename, events)
  if not err then
    if reload_timer then
      reload_timer:stop()
      reload_timer:close()
    end

    reload_timer = uv.new_timer()
    reload_timer:start(100, 0, vim.schedule_wrap(function()
      _G.reload_matugen_colors()
      if reload_timer then
        reload_timer:stop()
        reload_timer:close()
        reload_timer = nil
      end
    end))
  end
end))

vim.api.nvim_create_autocmd("Signal", {
  pattern = "SIGUSR1",
  callback = function()
    _G.reload_matugen_colors()
  end,
})

-- ============================================
-- ATAJOS DE VENTANAS Y NAVEGACIÓN
-- ============================================

-- Cerrar ventana con Ctrl+W
vim.keymap.set("n", "<C-w>", "<C-w>", { desc = "Window commands (native)" })

-- Navegar entre archivos (buffers) con Ctrl+Tab
vim.keymap.set("n", "<C-Tab>", ":bnext<CR>", { desc = "Next buffer (file)" })
vim.keymap.set("n", "<C-S-Tab>", ":bprev<CR>", { desc = "Previous buffer (file)" })

-- Navegación horizontal entre ventanas
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Focus left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Focus down window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Focus up window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Focus right window" })

-- Redimensionar ventanas
vim.keymap.set("n", "<C-Left>", "<C-w><", { desc = "Decrease width" })
vim.keymap.set("n", "<C-Right>", "<C-w>>", { desc = "Increase width" })
vim.keymap.set("n", "<C-Up>", "<C-w>+", { desc = "Increase height" })
vim.keymap.set("n", "<C-Down>", "<C-w>-", { desc = "Decrease height" })

-- ============================================
-- RENOMBRAR ARCHIVOS/DIRECTORIOS (F2)
-- ============================================

local function rename_current_file()
  local filename = vim.fn.expand("%:p")
  if filename == "" then
    vim.notify("No file is currently open", vim.log.levels.ERROR)
    return
  end

  local basename = vim.fn.expand("%:t")
  local dirname = vim.fn.expand("%:p:h")

  vim.ui.input({
    prompt = "New name: ",
    default = basename,
  }, function(new_name)
    if new_name == nil or new_name == "" then
      vim.notify("Rename cancelled", vim.log.levels.INFO)
      return
    end

    if new_name == basename then
      vim.notify("Name unchanged", vim.log.levels.INFO)
      return
    end

    local new_path = dirname .. "/" .. new_name

    if vim.fn.filereadable(new_path) == 1 or vim.fn.isdirectory(new_path) == 1 then
      vim.notify("File/Directory already exists: " .. new_name, vim.log.levels.ERROR)
      return
    end

    if vim.bo.modified then
      vim.cmd("write")
    end

    local success = os.rename(filename, new_path)
    if success then
      local buf = vim.api.nvim_get_current_buf()
      vim.cmd("bdelete!")
      vim.cmd("edit " .. new_path)
      vim.notify("Renamed to: " .. new_name, vim.log.levels.INFO)

      pcall(function()
        require("nvim-tree.api").tree.reload()
      end)
    else
      vim.notify("Failed to rename file", vim.log.levels.ERROR)
    end
  end)
end

local function rename_nvimtree_node()
  require("nvim-tree.api").fs.rename()
end

-- Keymaps para F2
vim.keymap.set("n", "<F2>", function()
  if vim.bo.filetype == "NvimTree" then
    rename_nvimtree_node()
  else
    rename_current_file()
  end
end, { desc = "Rename file/folder" })

-- ============================================
-- NAVEGACIÓN ENTRE EDITOR Y EXPLORADOR
-- ============================================

-- Moverse al explorador con Ctrl+h
vim.keymap.set("n", "<C-h>", function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "NvimTree" then
      vim.api.nvim_set_current_win(win)
      return
    end
  end
  vim.cmd("NvimTreeToggle")
end, { desc = "Focus or toggle file explorer" })

-- Moverse al editor desde el explorador
vim.keymap.set("n", "<C-l>", function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype ~= "NvimTree" then
      vim.api.nvim_set_current_win(win)
      return
    end
  end
end, { desc = "Focus editor window" })

-- Alternar entre editor y explorador
local function toggle_explorer_focus()
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_win_get_buf(current_win)

  if vim.bo[current_buf].filetype == "NvimTree" then
    vim.cmd("wincmd p")
  else
    local tree_open = false
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "NvimTree" then
        vim.api.nvim_set_current_win(win)
        tree_open = true
        break
      end
    end
    if not tree_open then
      vim.cmd("NvimTreeToggle")
    end
  end
end

vim.keymap.set("n", "<C-e>", toggle_explorer_focus, { desc = "Toggle explorer focus" })
vim.keymap.set("n", "<leader>e", toggle_explorer_focus, { desc = "Toggle explorer focus" })
vim.keymap.set("n", "<C-n>", function()
  vim.cmd("NvimTreeToggle")
end, { desc = "Open/close file explorer" })

-- Atajos para el explorador
vim.api.nvim_create_autocmd("FileType", {
  pattern = "NvimTree",
  callback = function()
    vim.keymap.set("n", "h", "NvimTreeClose", { buffer = true, desc = "Close explorer" })
    vim.keymap.set("n", "l", "NvimTreeOpen", { buffer = true, desc = "Open file/folder" })

    vim.keymap.set("n", "a", function()
      require("nvim-tree.api").fs.create()
    end, { buffer = true, desc = "Create file or directory" })

    vim.keymap.set("n", "A", function()
      require("nvim-tree.api").fs.create()
    end, { buffer = true, desc = "Create file or directory" })

    vim.keymap.set("n", "d", function()
      require("nvim-tree.api").fs.trash()
    end, { buffer = true, desc = "Move to trash" })

    vim.keymap.set("n", "y", function()
      require("nvim-tree.api").fs.copy.node()
    end, { buffer = true, desc = "Copy file" })

    vim.keymap.set("n", "p", function()
      require("nvim-tree.api").fs.paste()
    end, { buffer = true, desc = "Paste file" })
  end,
})

-- ============================================
-- KEYMAPS ADICIONALES PARA PRODUCTIVIDAD
-- ============================================

-- Navegación rápida entre errores
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous Diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next Diagnostic" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show Diagnostic" })

-- Corregir automáticamente
vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, { desc = "Code Action" })
vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, { desc = "Rename" })
vim.keymap.set("n", "<leader>h", vim.lsp.buf.hover, { desc = "Hover" })
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to Definition" })
vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Go to Declaration" })
vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "References" })
vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Implementation" })
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "Format" })

-- Debugging
vim.keymap.set("n", "<F5>", dap.continue, { desc = "Continue" })
vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Step Over" })
vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Step Into" })
vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Step Out" })
vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
vim.keymap.set("n", "<leader>B", dap.set_breakpoint, { desc = "Set Breakpoint" })
vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Open REPL" })

-- Trouble
vim.keymap.set("n", "<leader>xx", "<cmd>TroubleToggle<CR>", { desc = "Toggle Trouble" })
vim.keymap.set("n", "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<CR>", { desc = "Workspace Diagnostics" })
vim.keymap.set("n", "<leader>xd", "<cmd>TroubleToggle document_diagnostics<CR>", { desc = "Document Diagnostics" })

-- Terminal (pestaña nueva)
vim.keymap.set("n", "<leader>t", function()
  vim.cmd("tabnew term://" .. vim.o.shell)
end, { desc = "Open Terminal in new tab" })

-- Escapar modo terminal a modo normal con Ctrl + Esc
vim.keymap.set("t", "<C-Esc>", [[<C-\><C-n>]], { desc = "Escape terminal mode" })


-- Cerrar la pestaña actual con C-q
local function close_current_tab()
  if vim.fn.tabpagenr("$") > 1 then
    vim.cmd("tabclose")
  end
end
vim.keymap.set("t", "<C-q>", close_current_tab, { desc = "Close current tab" })
vim.keymap.set("n", "<C-q>", close_current_tab, { desc = "Close current tab" })

-- Markdown preview (navegador)
vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", { desc = "Toggle Markdown Preview" })

-- Crear nuevas ventanas
vim.keymap.set("n", "<leader>sv", ":vsplit<CR>", { desc = "Split vertical" })
vim.keymap.set("n", "<leader>sh", ":split<CR>", { desc = "Split horizontal" })
vim.keymap.set("n", "<leader>sc", ":close<CR>", { desc = "Close window" })
vim.keymap.set("n", "<leader>so", ":only<CR>", { desc = "Close others" })

-- Proyectos
vim.keymap.set("n", "<leader>rs", function()
  vim.cmd("!mvn spring-boot:run &")
end, { desc = "Run Spring Boot" })

vim.keymap.set("n", "<leader>rf", function()
  vim.cmd("!flutter run &")
end, { desc = "Run Flutter" })

vim.keymap.set("n", "<leader>rp", function()
  vim.cmd("!uvicorn main:app --reload &")
end, { desc = "Run FastAPI" })

-- ============================================
-- CONFIGURACIÓN ESPECÍFICA POR TIPO DE ARCHIVO
-- ============================================

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "java", "kotlin" },
  callback = function()
    vim.opt.tabstop = 4
    vim.opt.shiftwidth = 4
    vim.opt.expandtab = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "dart" },
  callback = function()
    vim.opt.tabstop = 2
    vim.opt.shiftwidth = 2
    vim.opt.expandtab = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python" },
  callback = function()
    vim.opt.tabstop = 4
    vim.opt.shiftwidth = 4
    vim.opt.expandtab = true
  end,
})

-- ============================================
-- MENSAJE FINAL
-- ============================================

vim.notify("✅ Neovim configurado para desarrollo completo!", vim.log.levels.INFO)
