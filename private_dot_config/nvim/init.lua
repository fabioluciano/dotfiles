-- This file simply bootstraps the installation of Lazy.nvim and then calls other files for execution
-- This file doesn't necessarily need to be touched, BE CAUTIOUS editing this file and proceed at your own risk.
local lazypath = vim.env.LAZY or vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

local function bootstrap_error(message)
  if #vim.api.nvim_list_uis() == 0 then
    vim.api.nvim_err_writeln(message)
    vim.cmd "cquit 1"
    return
  end
  vim.api.nvim_echo({ { message, "ErrorMsg" }, { "Press any key to exit...", "MoreMsg" } }, true, {})
  vim.fn.getchar()
  vim.cmd.quit()
end

if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
  if #vim.api.nvim_list_uis() == 0 then bootstrap_error(("lazy.nvim is missing at: %s"):format(lazypath)) end
  local result = vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch",
    "main",
    lazypath,
  }
  if vim.v.shell_error ~= 0 then bootstrap_error(("Error cloning lazy.nvim:\n%s\n"):format(result)) end
end

vim.opt.rtp:prepend(lazypath)

if not pcall(require, "lazy") then bootstrap_error(("Unable to load lazy from: %s\n"):format(lazypath)) end

require "lazy_setup"
require "polish"
