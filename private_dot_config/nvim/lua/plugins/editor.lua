---@type LazySpec
return {
  -- render-markdown (inline: astrocommunity import causa loop com packs ativos)
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "norg", "rmd", "org", "mdx" },
    opts = { file_types = { "markdown", "norg", "rmd", "org", "mdx" } },
  },

  -- img-clip (inline: astrocommunity import causa loop com packs ativos)
  {
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- multicursor (não existe no astrocommunity)
  {
    "jake-stewart/multicursor.nvim",
    keys = {
      { "<C-n>", mode = { "n", "x" }, desc = "Add cursor at next match" },
      { "<C-S-n>", mode = { "n", "x" }, desc = "Skip next match" },
      { "<Leader>ma", mode = { "n", "x" }, desc = "Add cursors to all matches" },
      { "<Esc>", mode = "n", desc = "Clear multicursors" },
    },
    config = function()
      local mc = require "multicursor-nvim"
      mc.setup()
      vim.keymap.set({ "n", "x" }, "<C-n>", function() mc.matchAddCursor(1) end)
      vim.keymap.set({ "n", "x" }, "<C-S-n>", function() mc.matchSkipCursor(1) end)
      vim.keymap.set({ "n", "x" }, "<Leader>ma", mc.matchAllAddCursors)
      vim.keymap.set("n", "<Esc>", function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        elseif mc.hasCursors() then
          mc.clearCursors()
        else
          vim.cmd.nohlsearch()
        end
      end)
    end,
  },

  -- hunk.nvim: diff editor para `jj diffedit --tool nvim`
  {
    "julienvincent/hunk.nvim",
    cmd = "DiffEditor",
    dependencies = { "MunifTanjim/nui.nvim" },
    config = function() require("hunk").setup() end,
  },

  {
    "kevinhwang91/nvim-bqf",
    ft = "qf",
    opts = { preview = { winblend = 0 } },
  },

  {
    "NvChad/nvim-colorizer.lua",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      filetypes = {
        "css",
        "scss",
        "sass",
        "less",
        "html",
        "vue",
        "svelte",
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "lua",
        "conf",
        "toml",
        "yaml",
      },
      user_default_options = {
        RGB = true,
        RRGGBB = true,
        names = false,
        RRGGBBAA = true,
        css = true,
        css_fn = true,
        mode = "virtualtext",
        virtualtext = "■",
        tailwind = true,
      },
    },
  },

  -- Fix nvim-notify E937 on Neovim 0.12+
  {
    "rcarriga/nvim-notify",
    opts = { stages = "static" },
  },
}
