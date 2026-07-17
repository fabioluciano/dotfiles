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
--   - Versions are synced across machines via chezmoi (Mason state is not).
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
    opts = {
      ensure_installed = {
        -- Debug adapters (nvim-dap; no mise equivalent)
        "codelldb",
        "js-debug-adapter",
        "java-debug-adapter",
        "java-test",
        "php-debug-adapter",
        "bash-debug-adapter",

        -- Go code-generation helpers (not in mise)
        "gomodifytags",
        "gotests",
        "iferr",
        "impl",

        -- LSPs not provided by mise
        "jdtls",       -- Java; also blocked by corporate network on work machines (download.eclipse.org)
        "lemminx",     -- XML
        "eslint-lsp",  -- JS/TS; mise ships oxlint instead

        -- PHP tooling not in mise
        "phpactor",
        "php-cs-fixer",
      },
    },
  },
}
