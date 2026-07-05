-- ╭──────────────────────────────────────────────────────────╮
-- │                    Polish Configuration                   │
-- │              Final setup after all plugins loaded         │
-- ╰──────────────────────────────────────────────────────────╯

-- Enable undercurl support in terminal
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

-- Custom filetypes
vim.filetype.add {
  extension = {
    zsh = "sh",
    sh = "sh",
    tmpl = "gotmpl",
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
    [".*%.tmpl"] = "gotmpl",
    [".*%.gotmpl"] = "gotmpl",
  },
}

-- Disable horizontal scroll in Neo-tree
vim.api.nvim_create_autocmd("FileType", {
  pattern = "neo-tree",
  callback = function()
    vim.wo.wrap = false
    vim.wo.sidescrolloff = 0
  end,
})

-- Diagnostic signs with icons
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

-- ╭──────────────────────────────────────────────────────────╮
-- │                    Spellcheck Setup                       │
-- │              Download spell files if missing              │
-- ╰──────────────────────────────────────────────────────────╯

-- Auto-download spell files for configured languages
local spell_dir = vim.fn.stdpath "data" .. "/site/spell"
vim.fn.mkdir(spell_dir, "p")

local function ensure_spell_file(lang)
  local spl = spell_dir .. "/" .. lang .. ".utf-8.spl"
  if vim.fn.filereadable(spl) == 0 then
    local url = "https://ftp.nluug.nl/pub/vim/runtime/spell/" .. lang .. ".utf-8.spl"
    vim.notify("Downloading " .. lang .. ".utf-8.spl…", vim.log.levels.INFO)
    vim.fn.system { "curl", "-fsSLo", spl, url }
    if vim.v.shell_error ~= 0 then
      vim.notify("Failed to download " .. lang .. " spell file", vim.log.levels.WARN)
    end
  end
end

vim.defer_fn(function()
  for _, lang in ipairs { "en", "pt" } do
    ensure_spell_file(lang)
  end
end, 500)
