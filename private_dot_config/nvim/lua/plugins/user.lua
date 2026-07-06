---@type LazySpec
return {
  -- Harpoon (inline: astrocommunity.motion.harpoon usa opts=function em dependency, causa loop)
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<Leader><Leader>a", function() require("harpoon"):list():add() end,                                                desc = "Harpoon add file" },
      { "<Leader><Leader>e", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end,             desc = "Harpoon menu" },
      { "<C-p>",             function() require("harpoon"):list():prev() end,                                               desc = "Harpoon prev mark" },
      { "<C-n>",             function() require("harpoon"):list():next() end,                                               desc = "Harpoon next mark" },
    },
  },

  -- render-markdown (inline: astrocommunity import causa loop com packs ativos)
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "norg", "rmd", "org", "mdx" },
    opts = { file_types = { "markdown", "norg", "rmd", "org", "mdx" } },
  },

  -- img-clip (inline: astrocommunity import causa loop com packs ativos)
  {
    "HakonHarnes/img-clip.nvim",
    event = "BufEnter",
    opts = {},
  },

  -- multicursor (não existe no astrocommunity)
  {
    "jake-stewart/multicursor.nvim",
    event = "BufReadPost",
    config = function() require("multicursor-nvim").setup() end,
  },

  -- hunk.nvim: diff editor para `jj diffedit --tool nvim`
  {
    "julienvincent/hunk.nvim",
    cmd = "DiffEditor",
    dependencies = { "MunifTanjim/nui.nvim" },
    config = function() require("hunk").setup() end,
  },

  -- kubectl
  {
    "Ramilito/kubectl.nvim",
    keys = { { "<leader>K", function() require("kubectl").toggle() end, desc = "kubectl.nvim" } },
    config = function() require("kubectl").setup() end,
  },

  -- sidekick
  { "folke/sidekick.nvim", event = "VeryLazy", opts = {} },

  -- tokyonight spell highlights
  {
    "folke/tokyonight.nvim",
    opts = {
      on_highlights = function(hl, c)
        hl.SpellBad   = { bg = "#3d2026", fg = "#f7768e", underline = true }
        hl.SpellCap   = { bg = "#3d3520", fg = "#e0af68", underline = true }
        hl.SpellLocal = { bg = "#203040", fg = "#7aa2f7", underline = true }
        hl.SpellRare  = { bg = "#302040", fg = "#bb9af7", underline = true }
      end,
    },
  },

  -- obsidian workspaces
  {
    "obsidian-nvim/obsidian.nvim",
    opts = {
      workspaces = {
        { name = "study", path = "~/Obsidian/study" },
        { name = "work",  path = "~/Obsidian/work" },
      },
      notes_subdir = "notes",
      new_notes_location = "notes_subdir",
      completion = { min_chars = 1 },
      follow_url_func = function(url)
        local cmd = vim.fn.has "mac" == 1 and "open" or "xdg-open"
        vim.fn.jobstart { cmd, url }
      end,
      daily_notes = { folder = "daily", date_format = "%Y-%m-%d" },
      templates = { folder = "templates", date_format = "%Y-%m-%d", time_format = "%H:%M" },
      note_id_func = function(title)
        local suffix
        if title then
          suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
        else
          suffix = ""
          for _ = 1, 4 do
            suffix = suffix .. string.char(math.random(65, 90))
          end
        end
        return os.date "%Y%m%d%H%M" .. "-" .. suffix
      end,
      ui = {
        enable = true,
        checkboxes = {
          [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
          ["x"] = { char = "", hl_group = "ObsidianDone" },
          [">"] = { char = "", hl_group = "ObsidianRightArrow" },
          ["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
        },
      },
    },
  },

  -- neominimap config
  {
    "Isrothy/neominimap.nvim",
    opts = {
      auto_enable = true,
      click = { enabled = true },
      exclude_filetypes = { "help", "bigfile", "neo-tree", "TelescopePrompt", "lazy", "mason", "toggleterm" },
      exclude_buftypes  = { "nofile", "nowrite", "quickfix", "terminal", "prompt" },
      buf_filter = function(bufnr)
        if vim.api.nvim_buf_get_name(bufnr) == "" then return false end
        if vim.bo[bufnr].buftype ~= "" then return false end
        return vim.api.nvim_buf_line_count(bufnr) > 1
          or (vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or "") ~= ""
      end,
    },
  },

  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>",            desc = "LazyGit" },
      { "<leader>gG", "<cmd>LazyGitCurrentFile<cr>", desc = "LazyGit (current file)" },
    },
  },

  -- Neo-tree
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      sources = { "document_symbols", "filesystem" },
      window = {
        width = 40,
        mappings = {
          ["<ScrollWheelLeft>"]  = "noop",
          ["<ScrollWheelRight>"] = "noop",
        },
      },
      default_component_configs = {
        indent = {
          with_expanders = true,
          expander_collapsed = "",
          expander_expanded  = "",
        },
        icon = {
          folder_closed      = "\u{e5ff}",
          folder_open        = "\u{e5fe}",
          folder_empty       = "\u{f115}",
          folder_empty_open  = "\u{f115}",
        },
        git_status = {
          symbols = {
            added     = "\u{f457}",
            modified  = "\u{f459}",
            deleted   = "\u{f458}",
            renamed   = "\u{f45a}",
            untracked = "\u{f128}",
            ignored   = "\u{f474}",
            unstaged  = "\u{f06a}",
            staged    = "\u{f055}",
            conflict  = "\u{eb37}",
          },
        },
      },
      filesystem = {
        filtered_items = {
          visible        = true,
          hide_dotfiles  = false,
          hide_gitignored = false,
        },
        use_libuv_file_watcher = true,
        group_empty_dirs = true,
        follow_current_file = { enabled = false },
        hijack_netrw_behavior = "disabled",
      },
    },
  },

  -- Better quick fix list
  {
    "kevinhwang91/nvim-bqf",
    ft = "qf",
    opts = { preview = { winblend = 0 } },
  },

  -- Better marks
  {
    "chentoast/marks.nvim",
    event = "BufReadPost",
    opts = { default_mappings = true, signs = true, mappings = {} },
  },

  -- Undo tree
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = { { "<leader>U", "<cmd>UndotreeToggle<cr>", desc = "Toggle Undotree" } },
  },

  -- Color highlighter
  {
    "NvChad/nvim-colorizer.lua",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      filetypes = {
        "css", "scss", "sass", "less", "html", "vue", "svelte",
        "javascript", "javascriptreact", "typescript", "typescriptreact",
        "lua", "conf", "toml", "yaml",
      },
      user_default_options = {
        RGB = true, RRGGBB = true, names = false, RRGGBBAA = true,
        css = true, css_fn = true,
        mode = "virtualtext", virtualtext = "■",
        tailwind = true,
      },
    },
  },

  -- Better fold
  {
    "kevinhwang91/nvim-ufo",
    dependencies = "kevinhwang91/promise-async",
    event = "BufReadPost",
    opts = {
      provider_selector = function() return { "treesitter", "indent" } end,
    },
    init = function()
      vim.o.foldcolumn    = "1"
      vim.o.foldlevel     = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable    = true
      vim.o.foldmethod    = "expr"
      vim.o.foldexpr      = "v:lua.vim.treesitter.foldexpr()"
    end,
    keys = {
      { "zR", function() require("ufo").openAllFolds() end,              desc = "Open all folds" },
      { "zM", function() require("ufo").closeAllFolds() end,             desc = "Close all folds" },
      { "zK", function() require("ufo").peekFoldedLinesUnderCursor() end, desc = "Peek fold" },
    },
  },

  {
    "akinsho/toggleterm.nvim",
    opts = {
      size = function(term)
        if term.direction == "horizontal" then return math.floor(vim.o.lines * 0.25)
        elseif term.direction == "vertical" then return math.floor(vim.o.columns * 0.4)
        end
      end,
      direction  = "horizontal",
      shell      = vim.o.shell,
      float_opts = { border = "rounded" },
      persist_size = false,
    },
  },

  {
    "ryanmsnyder/toggleterm-manager.nvim",
    lazy = true,
    init = function(plugin) require("astrocore").on_load("telescope.nvim", plugin.name) end,
    dependencies = {
      "akinsho/toggleterm.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
      -- NOTE: astrocore mapping fragment omitido intencionalmente — declarado em astrocore.lua
    },
    opts = function(_, opts)
      local term_icon = require("astroui").get_icon "Terminal"
      local actions   = require("toggleterm-manager").actions
      return require("astrocore").extend_tbl(opts, {
        titles   = { prompt = term_icon .. " Terminals" },
        results  = { term_icon = term_icon },
        mappings = {
          n = {
            ["<CR>"] = { action = actions.toggle_term,  exit_on_action = true },
            ["r"]    = { action = actions.rename_term,  exit_on_action = false },
            ["d"]    = { action = actions.delete_term,  exit_on_action = false },
            ["n"]    = { action = actions.create_term,  exit_on_action = false },
          },
          i = {
            ["<CR>"]   = { action = actions.toggle_term, exit_on_action = true },
            ["<C-r>"]  = { action = actions.rename_term, exit_on_action = false },
            ["<C-d>"]  = { action = actions.delete_term, exit_on_action = false },
            ["<C-n>"]  = { action = actions.create_term, exit_on_action = false },
          },
        },
      })
    end,
  },

  -- Fix nvim-notify E937 on Neovim 0.12+
  {
    "rcarriga/nvim-notify",
    opts = { stages = "static" },
  },

  -- Formatters per filetype
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.go          = { "gofumpt", "goimports" }
      opts.formatters_by_ft.python      = { "ruff_format" }
      opts.formatters_by_ft.javascript  = { "biome" }
      opts.formatters_by_ft.javascriptreact = { "biome" }
      opts.formatters_by_ft.typescript  = { "biome" }
      opts.formatters_by_ft.typescriptreact = { "biome" }
      opts.formatters_by_ft.lua         = { "stylua" }
    end,
  },
}
