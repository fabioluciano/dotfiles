-- Mason configuration — Strategy D: mise is the authoritative tool provider.
--
-- mise (mise/config.toml, chezmoi-synced) installs every LSP/formatter/linter
-- the editor needs and puts them on $PATH via shims. To stop Mason's copies
-- from shadowing mise, mason.nvim is configured with PATH = "skip" so Mason's
-- bin/ is NOT prepended to PATH — exepath resolution always falls through to
-- mise. lspconfig/conform/nvim-lint therefore use the mise binaries, identical
-- to what runs in the shell.
--
-- Consequences:
--   - Editor and shell share the exact same binaries (no version drift).
--   - Tool ownership is synced across machines; global versions follow latest.
--   - Mason install failures become non-fatal: if a Mason package fails to
--     build, the LSP still starts from the mise binary.
--
-- This ensure_installed list only contains tools mise CANNOT provide: nvim-dap
-- debug adapters, Java/XML tooling behind corporate-network blocks, Go codegen
-- helpers, and PHP tooling. Everything else is owned by mise.

---@type LazySpec
return {
  -- Do not let Mason shadow mise: keep mason/bin off the Neovim PATH so tools
  -- resolve to the mise shims.
  {
    "mason.nvim",
    opts = { PATH = "skip" },
  },

  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = function(_, opts)
      local mise_owned = {
        "angular-language-server",
        "bash-language-server",
        "basedpyright",
        "biome",
        "cmake-language-server",
        "cmakelint",
        "dockerfile-language-server",
        "elixir-ls",
        "gofumpt",
        "goimports",
        "golangci-lint",
        "gopls",
        "helm-ls",
        "intelephense",
        "lua-language-server",
        "markdownlint",
        "marksman",
        "mdx-analyzer",
        "ruff",
        "rust-analyzer",
        "shfmt",
        "sql-language-server",
        "stylua",
        "tailwindcss-language-server",
        "taplo",
        "terraform-ls",
        "tflint",
        "tinymist",
        "tree-sitter-cli",
        "typescript-language-server",
        "vue-language-server",
        "yaml-language-server",
        "yamlfmt",
        "yamllint",
        "zls",
      }
      local owned = {}
      for _, package in ipairs(mise_owned) do
        owned[package] = true
      end

      local mason_only = {
        -- Debug adapters and helpers without a configured mise source.
        "codelldb",
        "js-debug-adapter",
        "java-debug-adapter",
        "java-test",
        "php-debug-adapter",
        "bash-debug-adapter",
        "gomodifytags",
        "gotests",
        "iferr",
        "impl",
        -- Mason is the single cross-platform source for Java/XML tooling.
        "jdtls",
        "lemminx",
        "phpactor",
        "php-cs-fixer",
      }

      local seen, packages = {}, {}
      for _, package in ipairs(vim.list_extend(opts.ensure_installed or {}, mason_only)) do
        if not owned[package] and not seen[package] then
          seen[package] = true
          packages[#packages + 1] = package
        end
      end
      opts.ensure_installed = packages
    end,
  },
}
