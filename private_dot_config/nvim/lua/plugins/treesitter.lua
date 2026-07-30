-- Customize Treesitter
-- --------------------
-- Treesitter customizations are handled with AstroCore
-- as nvim-treesitter simply provides a download utility for parsers

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    treesitter = {
      highlight = true,
      indent = true,
      auto_install = true,
      ensure_installed = {
        -- Core
        "lua",
        "vim",
        "vimdoc",
        "query",

        -- Web
        "html",
        "css",
        "scss",
        "javascript",
        "typescript",
        "tsx",
        "vue",
        "angular",
        "svelte",
        "astro",

        -- Markup
        "markdown",
        "markdown_inline",
        "json",
        "jsonc",
        "yaml",
        "toml",
        "xml",

        -- Languages
        "python",
        "go",
        "gomod",
        "gosum",
        "rust",
        "php",
        "java",
        "sql",
        "just",

        -- Shell/Config
        "bash",
        "fish",
        "dockerfile",
        "terraform",
        "hcl",
        "helm",
        "cmake",

        -- Other
        "regex",
        "gitignore",
        "git_config",
        "git_rebase",
        "gitcommit",
        "gitattributes",
        "diff",
      },
    },
  },
}
