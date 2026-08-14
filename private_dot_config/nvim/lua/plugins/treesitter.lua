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
        "lua",
        "vim",
        "vimdoc",
        "query",

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

        "markdown",
        "markdown_inline",
        "json",
        "jsonc",
        "yaml",
        "toml",
        "xml",

        "python",
        "go",
        "gomod",
        "gosum",
        "gotmpl",
        "rust",
        "php",
        "java",
        "sql",
        "just",

        "bash",
        "fish",
        "dockerfile",
        "terraform",
        "hcl",
        "helm",
        "cmake",

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
