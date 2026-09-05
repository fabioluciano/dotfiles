---@type LazySpec
return {
  {
    "akinsho/toggleterm.nvim",
    cmd = { "ToggleTerm", "TermExec" },
    keys = {
      {
        "<Leader>tL",
        function()
          vim.cmd "Neotree filesystem left"
          vim.cmd "wincmd l"
          vim.cmd "ToggleTerm direction=horizontal"
          vim.cmd "wincmd p"
        end,
        desc = "Open explorer and terminal layout",
      },
    },
    opts = {
      size = function(term)
        if term.direction == "horizontal" then
          return math.floor(vim.o.lines * 0.25)
        elseif term.direction == "vertical" then
          return math.floor(vim.o.columns * 0.4)
        end
      end,
      direction = "horizontal",
      shell = vim.o.shell,
      float_opts = { border = "rounded" },
      persist_size = false,
    },
  },
}
