local M = {}

function M.is_large(bufnr)
  bufnr = bufnr or 0
  if vim.api.nvim_buf_line_count(bufnr) > 10000 then return true end

  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then return false end
  local stat = (vim.uv or vim.loop).fs_stat(name)
  return stat ~= nil and stat.size > 1024 * 500
end

return M
