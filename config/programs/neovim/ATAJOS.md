# Atajos de Neovim y plugins instalados

Configuración en `config/programs/neovim/default.nix` (plugins/paquetes) y
`config/programs/neovim/nvim/init.lua` (atajos y configuración).

> `<leader>` = **Espacio** · `<C-x>` = Ctrl+x · `:help` para docs.

---

## 1. Navegación y ventanas

| Atajo                    | Acción                                   |
| ------------------------ | ---------------------------------------- |
| `<C-h>`                  | Enfocar/toggle el explorador (nvim-tree) |
| `<C-l>`                  | Enfocar la ventana del editor            |
| `<C-e>`                  | Alternar foco editor/explorador          |
| `<C-n>`                  | Abrir/cerrar el explorador de archivos   |
| `<C-Tab>` / `<C-S-Tab>`  | Buffer (archivo) siguiente / anterior    |
| `<C-j>` / `<C-k>`        | Bajar / subir de ventana                 |
| `<C-Left>` / `<C-Right>` | Reducir / aumentar ancho                 |
| `<C-Up>` / `<C-Down>`    | Aumentar / reducir alto                  |
| `<leader>sv`             | Split vertical                           |
| `<leader>sh`             | Split horizontal                         |
| `<leader>sc`             | Cerrar ventana                           |
| `<leader>so`             | Cerrar las demás ventanas                |

## 2. Búsqueda (Telescope)

| Atajo        | Acción                     |
| ------------ | -------------------------- |
| `<leader>ff` | Buscar archivos            |
| `<leader>fg` | Búsqueda en vivo (ripgrep) |
| `<leader>fb` | Buscar buffers abiertos    |
| `<leader>fh` | Buscar ayuda               |

## 3. LSP (diagnósticos, definiciones, refactors)

| Atajo       | Acción                            |
| ----------- | --------------------------------- |
| `gd`        | Ir a definición                   |
| `gD`        | Ir a declaración                  |
| `gr`        | Referencias                       |
| `gi`        | Implementaciones                  |
| `<leader>h` | Hover / documentación             |
| `<leader>a` | Acciones de código (code actions) |
| `<leader>r` | Renombrar símbolo                 |
| `<leader>f` | Formatear archivo                 |
| `[d` / `]d` | Diagnóstico anterior / siguiente  |
| `<leader>e` | Mostrar diagnóstico en float      |

## 4. Completado (nvim-cmp) y snippets (LuaSnip)

| Atajo             | Acción                            |
| ----------------- | --------------------------------- |
| `<C-n>` / `<C-p>` | Siguiente / anterior item         |
| `<C-Space>`       | Forzar completado                 |
| `<CR>`            | Confirmar selección               |
| `<Tab>`           | Siguiente item o expandir snippet |
| `<C-d>` / `<C-f>` | Desplazar docs (-4 / +4)          |

Fuentes: LSP, LuaSnip, buffer, path, Dadbod (SQL).

## 5. Debugging (nvim-dap)

| Atajo        | Acción                    |
| ------------ | ------------------------- |
| `<F5>`       | Continuar / iniciar debug |
| `<F10>`      | Step over                 |
| `<F11>`      | Step into                 |
| `<F12>`      | Step out                  |
| `<leader>b`  | Toggle breakpoint         |
| `<leader>B`  | Fijar breakpoint          |
| `<leader>dr` | Abrir REPL                |

Configuraciones incluidas: Java/Spring Boot, Python/FastAPI, Dart/Flutter.

## 6. Trouble (diagnósticos en panel)

| Atajo        | Acción                     |
| ------------ | -------------------------- |
| `<leader>xx` | Toggle Trouble             |
| `<leader>xw` | Diagnósticos del workspace |
| `<leader>xd` | Diagnósticos del documento |

## 7. Explorador de archivos (nvim-tree) — dentro del árbol

| Tecla  | Acción                                              |
| ------ | --------------------------------------------------- |
| `h`    | Cerrar explorador                                   |
| `l`    | Abrir archivo/carpeta                               |
| `a`    | Crear archivo, Crear directorio/                    |
| `d`    | Mover a papelera                                    |
| `y`    | Copiar archivo                                      |
| `p`    | Pegar archivo                                       |
| `<F2>` | Renombrar archivo/carpeta (en editor y en el árbol) |

## 8. Terminal y miscelánea

| Atajo        | Acción                                 |
| ------------ | -------------------------------------- |
| `<leader>t`  | Abrir terminal (pestaña nueva)         |
| `<C-Esc>`    | Poner la terminal en modo normal       |
| `<leader>mp` | Toggle preview de markdown (navegador) |
| `<leader>e`  | Mostrar diagnóstico flotante           |
| `<F2>`       | Renombrar archivo actual               |

> Nota: `<leader>e` está definido dos veces (explorador en la sección 1 y
> diagnóstico flotante). Gana el de diagnóstico flotante (`init.lua` ~línea 811).
> El explorador se alterna con `<C-e>`.

## 9. Atajos por framework/lenguaje

| Atajo        | Framework   | Acción                      |
| ------------ | ----------- | --------------------------- |
| `<leader>rs` | Spring Boot | `mvn spring-boot:run`       |
| `<leader>rf` | Flutter     | `flutter run`               |
| `<leader>rp` | FastAPI     | `uvicorn main:app --reload` |

---

## Plugins instalados

### Generales / UI

| Plugin                  | Uso                                   |
| ----------------------- | ------------------------------------- |
| `catppuccin-nvim`       | Tema (flavour mocha, colores matugen) |
| `nvim-web-devicons`     | Iconos                                |
| `lualine-nvim`          | Barra de estado                       |
| `bufferline-nvim`       | Pestañas de buffers                   |
| `indent-blankline-nvim` | Guías de indentación                  |
| `gitsigns-nvim`         | Marcas de git en el gutter            |
| `which-key-nvim`        | Popup de atajos al pulsar `<leader>`  |
| `nvim-tree-lua`         | Explorador de archivos                |
| `plenary-nvim`          | Dependencia de telescope              |

### Búsqueda y edición

| Plugin                     | Uso                               |
| -------------------------- | --------------------------------- |
| `telescope-nvim`           | Búsqueda fzf-style                |
| `telescope-ui-select-nvim` | Select de UI nativa               |
| `nvim-autopairs`           | Autocierre de paréntesis/comillas |
| `comment-nvim`             | Comentar código                   |

### LSP, completado y snippets

| Plugin                                          | Uso                          |
| ----------------------------------------------- | ---------------------------- |
| `nvim-lspconfig`                                | Configuración de LSP servers |
| `nvim-cmp` + `cmp-nvim-lsp`                     | Autocompletado               |
| `cmp-buffer` / `cmp-path` / `cmp-cmdline`       | Fuentes de completado        |
| `luasnip` + `cmp_luasnip` + `friendly-snippets` | Snippets                     |

### Formateo / linting (none-ls, fork de null-ls)

| Builtin                    | Lenguaje       |
| -------------------------- | -------------- |
| `black`, `ruff`            | Python         |
| `google_java_format`       | Java           |
| `prettierd`                | JS/TS/HTML/CSS |
| `dart_format`              | Dart           |
| `sql_formatter`            | SQL            |
| `nixpkgs_fmt`              | Nix            |
| `markdownlint`             | Markdown       |

### Debugging

| Plugin                  | Uso                |
| ----------------------- | ------------------ |
| `nvim-dap`              | Motor de debugging |
| `nvim-dap-ui`           | UI de debugging    |
| `nvim-dap-virtual-text` | Valores en línea   |

### Stack específico

| Plugin                                                   | Uso                                 |
| -------------------------------------------------------- | ----------------------------------- |
| `vim-javacomplete2`                                      | Completado Java                     |
| `vim-dadbod` + `vim-dadbod-ui` + `vim-dadbod-completion` | Bases de datos / SQL                |
| `none-ls-nvim`                                           | Formateo y linting                  |
| `markdown-preview-nvim`                                  | Preview de markdown en el navegador |
| `nvim-treesitter-context`                                | Cabecera de contexto al scrollear   |
| `trouble-nvim`                                           | Panel de diagnósticos               |

## Herramientas / LSP por lenguaje

| Lenguaje / Framework | Paquetes instalados (LSP + extras)                                            |
| -------------------- | ----------------------------------------------------------------------------- |
| Python               | `pyright`, `black`, `ruff`                                                    |
| Nix                  | `nil`, `nixpkgs-fmt`                                                          |
| Java / Spring Boot   | `jdt-language-server`, `google-java-format`, `yaml-language-server`           |
| C++ / Qt             | `clangd` (vía `clang-tools`), `qmlls` (vía `qt6.qtdeclarative`)               |
| Kotlin               | `kotlin-language-server`                                                      |
| Dart / Flutter       | `flutter`, `dart-sass`                                                        |
| JS / TS / Angular    | `ts_ls`, `angularls`, `vscode-langservers-extracted` (html/css/json), `eslint`|
| PostgreSQL / SQL     | `sqls`                                                                        |
| Markdown             | `markdown-preview-nvim` (+ `nodejs`), `markdownlint-cli`                      |
| General              | `ripgrep`, `fd`, `shellcheck`                                                 |

> Para preview de markdown fuera de nvim (p.ej. en yazi): `glow` (en `home.packages`).
> yazi usa glow automáticamente para `.md`.

## Lenguajes con resaltado Treesitter

java, kotlin, dart, javascript, typescript, html, css, json, yaml, xml, sql,
python, lua, nix, bash, dockerfile.

## Notas

- Los paquetes se instalan vía Nix (no se descargan dentro de nvim). Cualquier
  LSP/formateador extra debe añadirse en `default.nix` → `extraPackages`.
- Los plugins se declaran en `default.nix` → `plugins`; la configuración en
  `nvim/init.lua`. Ambos archivos se despliegan por home-manager (symlinks al
  nix store) y requieren **commitear antes de `./deploy.sh`**.
