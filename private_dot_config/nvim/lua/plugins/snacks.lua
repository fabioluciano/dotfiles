---@type LazySpec
return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    local legacy_filetypes = { "help", "alpha", "dashboard", "Trouble", "lazy", "neo-tree" }
    local core_filter = opts.indent and opts.indent.filter

    opts.indent = opts.indent or {}
    opts.indent.indent = { char = "│" }
    opts.indent.scope = { char = "│", enabled = false }
    opts.indent.animate = { enabled = false }
    opts.indent.filter = function(bufnr)
      return (not core_filter or core_filter(bufnr)) and not vim.tbl_contains(legacy_filetypes, vim.bo[bufnr].filetype)
    end

    opts.scope = opts.scope or {}
    opts.scope.enabled = false
  end,
}
