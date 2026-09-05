---@type LazySpec
return {
  {
    "folke/tokyonight.nvim",
    opts = {
      on_highlights = function(hl, c)
        hl.SnacksGhNormalFloat = { fg = c.fg, bg = c.bg_float }
        hl.SpellBad = { bg = "#3d2026", fg = "#f7768e", underline = true }
        hl.SpellCap = { bg = "#3d3520", fg = "#e0af68", underline = true }
        hl.SpellLocal = { bg = "#203040", fg = "#7aa2f7", underline = true }
        hl.SpellRare = { bg = "#302040", fg = "#bb9af7", underline = true }
      end,
    },
  },
}
