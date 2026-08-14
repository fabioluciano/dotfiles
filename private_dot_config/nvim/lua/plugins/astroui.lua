---@type LazySpec
return {
  "AstroNvim/astroui",
  ---@type AstroUIOpts
  opts = {
    colorscheme = "tokyonight-night",

    highlights = {
      init = {
        Normal = { bg = "NONE" },
        NormalNC = { bg = "NONE" },
        NormalFloat = { bg = "NONE" },
        FloatBorder = { bg = "NONE" },
        FloatTitle = { bg = "NONE" },
        SignColumn = { bg = "NONE" },
        EndOfBuffer = { bg = "NONE" },
        MsgArea = { bg = "NONE" },
        NeoTreeNormal = { bg = "NONE" },
        NeoTreeNormalNC = { bg = "NONE" },
        NeoTreeEndOfBuffer = { bg = "NONE" },
        TelescopeNormal = { bg = "NONE" },
        TelescopeBorder = { bg = "NONE" },
        WhichKeyFloat = { bg = "NONE" },
        CursorLineNr = { fg = "#7aa2f7", bold = true },
        Visual = { bg = "#33467c" },
        VisualNOS = { bg = "#33467c" },
      },
    },

    status = {
      separators = {
        left = { "", " " },
        right = { " ", "" },
      },
      colors = function(hl)
        local get_hlgroup = require("astroui").get_hlgroup
        hl.git_branch_fg = get_hlgroup("Conditional").fg
        hl.git_added = get_hlgroup("String").fg
        hl.git_changed = get_hlgroup("Special").fg
        hl.git_removed = get_hlgroup("Error").fg
        hl.blank_bg = "NONE"
        hl.file_info_bg = "NONE"
        hl.nav_icon_bg = "NONE"
        hl.folder_icon_bg = "NONE"
        return hl
      end,
    },

    icons = {
      LSPLoading1 = "⠋",
      LSPLoading2 = "⠙",
      LSPLoading3 = "⠹",
      LSPLoading4 = "⠸",
      LSPLoading5 = "⠼",
      LSPLoading6 = "⠴",
      LSPLoading7 = "⠦",
      LSPLoading8 = "⠧",
      LSPLoading9 = "⠇",
      LSPLoading10 = "⠏",
      GitAdd = "",
      GitChange = "",
      GitDelete = "",
      DiagnosticError = "",
      DiagnosticHint = "󰌵",
      DiagnosticInfo = "󰋼",
      DiagnosticWarn = "",
      FolderClosed = "",
      FolderOpen = "",
      FolderEmpty = "󰜌",
      ActiveLSP = "",
      ActiveTS = "",
      BufferClose = "󰅖",
      Search = "",
      Selected = "❯",
    },
  },
}
