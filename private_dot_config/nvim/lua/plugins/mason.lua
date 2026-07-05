-- Mason tool installer: ensures LSP servers and formatters/linters are present
-- in neovim's Mason registry even when no file of that type is open.
--
-- Several tools here are *also* installed system-wide via mise (mise/config.toml).
-- That duplication is intentional:
--   - mise  → system-wide shims on $PATH (used by shells, editors, scripts)
--   - Mason → nvim-local copies registered with lspconfig/conform/nvim-lint
-- Tools managed by mise are annotated with [mise] below.

---@type LazySpec
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = {
        -- Lua
        "lua-language-server", -- [mise]
        "stylua",              -- [mise]

        -- Python
        "ruff",    -- [mise: aqua:astral-sh/ruff]
        "debugpy", -- [mise: pipx:debugpy]

        -- Go
        "gopls",         -- [mise: go:golang.org/x/tools/gopls]
        "gofumpt",       -- [mise]
        "goimports",     -- [mise: go:golang.org/x/tools/cmd/goimports]
        "golangci-lint", -- [mise]
        "delve",         -- [mise: go:github.com/go-delve/delve/cmd/dlv]

        -- TypeScript/JavaScript
        "typescript-language-server", -- [mise: npm:typescript-language-server]
        "eslint-lsp",
        "biome", -- [mise: npm:@biomejs/biome]

        -- Angular
        "angular-language-server",

        -- Vue
        "vue-language-server",

        -- HTML/CSS
        "html-lsp",
        "css-lsp",
        "tailwindcss-language-server", -- [mise: npm:@tailwindcss/language-server]

        -- JSON/YAML
        "json-lsp",
        "yaml-language-server", -- [mise: npm:yaml-language-server]
        "yamllint",
        "yamlfmt",

        -- Bash
        "bash-language-server",
        "shfmt", -- [mise]

        -- Docker
        "dockerfile-language-server",
        "docker-compose-language-service",

        -- Terraform
        "terraform-ls", -- [mise]
        "tflint",

        -- Rust
        "rust-analyzer", -- [mise]

        -- PHP
        "intelephense",

        -- Java
        "jdtls",

        -- SQL
        "sqlls",

        -- XML
        "lemminx",

        -- TOML
        "taplo",

        -- Helm / Kubernetes
        "helm-ls",

        -- Markdown
        "marksman",
        "markdownlint",

        -- MDX
        "mdx-analyzer",

        -- CMake
        "cmake-language-server",
        "cmakelint",

        -- General
        "tree-sitter-cli",
      },
    },
  },
}
