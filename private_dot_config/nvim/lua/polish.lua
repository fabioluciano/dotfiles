vim.opt.termguicolors = true
vim.o.autoread = true -- Required for opencode-nvim events.reload (auto-reload buffers edited by opencode)

-- Workaround: Neovim 0.12 + tmux mode 2031 (DECSET) incompatibility
-- Prevents silent exit when tmux sends unexpected terminal mode responses
vim.opt.termsync = false
-- Undercurl support for terminals that support it (kitty, wezterm, ghostty, etc.)
vim.cmd [[
  let &t_Cs = "\e[4:3m"
  let &t_Ce = "\e[4:0m"
]]

vim.filetype.add {
  extension = {
    zsh = "sh",
    sh = "sh",
    conf = "conf",
    env = "sh",
  },
  filename = {
    [".zshrc"] = "sh",
    [".zshenv"] = "sh",
    [".zprofile"] = "sh",
    [".bashrc"] = "sh",
    [".bash_profile"] = "sh",
    ["Brewfile"] = "ruby",
    ["Justfile"] = "just",
    ["justfile"] = "just",
    [".envrc"] = "sh",
    [".env"] = "sh",
    [".env.local"] = "sh",
    [".env.example"] = "sh",
    ["Dockerfile"] = "dockerfile",
    ["docker-compose.yml"] = "yaml.docker-compose",
    ["docker-compose.yaml"] = "yaml.docker-compose",
    ["compose.yml"] = "yaml.docker-compose",
    ["compose.yaml"] = "yaml.docker-compose",
  },
  pattern = {
    ["%.env%.[%w_.-]+"] = "sh",
    ["Dockerfile.*"] = "dockerfile",
    [".*%.sh%.tmpl"] = "sh",
    [".*%.zsh%.tmpl"] = "sh",
    [".*%.bash%.tmpl"] = "sh",
    [".*%.toml%.tmpl"] = "toml",
    [".*%.json%.tmpl"] = "json",
    [".*%.jsonc%.tmpl"] = "jsonc",
    [".*%.yaml%.tmpl"] = "yaml",
    [".*%.yml%.tmpl"] = "yaml",
    [".*%.lua%.tmpl"] = "lua",
    [".*%.md%.tmpl"] = "markdown",
    [".*%.gotmpl"] = "gotmpl",
  },
}

vim.api.nvim_create_autocmd("FileType", {
  pattern = "neo-tree",
  callback = function()
    vim.wo.wrap = false
    vim.wo.sidescrolloff = 0
  end,
})

vim.diagnostic.config {
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.HINT] = "󰌵",
      [vim.diagnostic.severity.INFO] = "󰋼",
    },
  },
}

local spell_dir = vim.fn.stdpath "data" .. "/site/spell"
local spell_downloads = {}

local function has_spell_file(lang)
  if vim.fn.filereadable(spell_dir .. "/" .. lang .. ".utf-8.spl") == 1 then return true end
  for path in vim.gsplit(vim.o.runtimepath, ",", { plain = true }) do
    if vim.fn.filereadable(path .. "/spell/" .. lang .. ".utf-8.spl") == 1 then return true end
  end
  return false
end

local function ensure_spell_file(lang, force)
  if #vim.api.nvim_list_uis() == 0 or (not force and has_spell_file(lang)) or spell_downloads[lang] then return end
  if vim.fn.executable "curl" ~= 1 then
    vim.notify_once("curl ausente; spellfiles não serão baixados", vim.log.levels.WARN)
    return
  end

  vim.fn.mkdir(spell_dir, "p")
  local destination = spell_dir .. "/" .. lang .. ".utf-8.spl"
  local temporary = destination .. ".tmp." .. vim.fn.getpid()
  local url = "https://ftp.nluug.nl/pub/vim/runtime/spell/" .. lang .. ".utf-8.spl"
  spell_downloads[lang] = true
  vim.system({ "curl", "-fsSL", "--connect-timeout", "10", "--max-time", "60", "-o", temporary, url }, function(result)
    spell_downloads[lang] = nil
    local stat = (vim.uv or vim.loop).fs_stat(temporary)
    if result.code == 0 and stat and stat.size > 0 then
      local ok, err = (vim.uv or vim.loop).fs_rename(temporary, destination)
      if not ok then
        (vim.uv or vim.loop).fs_unlink(temporary)
        vim.schedule(
          function() vim.notify("Falha ao promover spellfile " .. lang .. ": " .. tostring(err), vim.log.levels.WARN) end
        )
      end
    else
      (vim.uv or vim.loop).fs_unlink(temporary)
      vim.schedule(function() vim.notify("Falha ao baixar spellfile " .. lang, vim.log.levels.WARN) end)
    end
  end)
end

vim.api.nvim_create_user_command("UpdateSpellFiles", function()
  for _, lang in ipairs { "en", "pt" } do
    ensure_spell_file(lang, true)
  end
end, { desc = "Download/update Vim spell files asynchronously" })

vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "spell",
  callback = function()
    if vim.v.option_new == "1" then
      for _, lang in ipairs(vim.opt_local.spelllang:get()) do
        ensure_spell_file(lang, false)
      end
    end
  end,
})

-- AstroNvim (astrocore) maintains `vim.t.bufs` and fires the `AstroBufsUpdated`
-- User autocmd whenever the buffer list changes. Filter unnamed/scratch buffers
-- (no-name, quickfix-like) out of that list so buffer cycling/resession ignore
-- them. `vim.t.bufs` is set by astrocore (lua/astrocore/buffer.lua), not by us.
vim.api.nvim_create_autocmd("User", {
  pattern = "AstroBufsUpdated",
  callback = function()
    if not vim.t.bufs then return end
    local filtered = vim.tbl_filter(
      function(bufnr) return vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_name(bufnr) ~= "" end,
      vim.t.bufs
    )
    if #filtered ~= #vim.t.bufs then vim.t.bufs = filtered end
  end,
})
