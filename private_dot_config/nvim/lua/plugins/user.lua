---@type LazySpec
return {
  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>",            desc = "LazyGit" },
      { "<leader>gG", "<cmd>LazyGitCurrentFile<cr>", desc = "LazyGit (current file)" },
    },
  },

  -- Neo-tree file explorer customization
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      sources = { "document_symbols", "filesystem" },
      default_component_configs = {
        indent = {
          with_expanders = true,
          expander_collapsed = "",
          expander_expanded = "",
        },
        icon = {
          folder_closed = "\u{e5ff}",
          folder_open = "\u{e5fe}",
          folder_empty = "\u{f115}",
          folder_empty_open = "\u{f115}",
        },
        git_status = {
          symbols = {
            added = "\u{f457}",
            modified = "\u{f459}",
            deleted = "\u{f458}",
            renamed = "\u{f45a}",
            untracked = "\u{f128}",
            ignored = "\u{f474}",
            unstaged = "\u{f06a}",
            staged = "\u{f055}",
            conflict = "\u{eb37}",
          },
        },
      },
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
        use_libuv_file_watcher = true,
        group_empty_dirs = true,
        follow_current_file = {
          enabled = false,
        },
      },
    },
  },

  -- Better quick fix list
  {
    "kevinhwang91/nvim-bqf",
    ft = "qf",
    opts = {
      preview = {
        winblend = 0,
      },
    },
  },

  -- Better marks
  {
    "chentoast/marks.nvim",
    event = "BufReadPost",
    opts = {
      default_mappings = true,
      signs = true,
      mappings = {},
    },
  },

  -- Undo tree visualization
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = {
      { "<leader>U", "<cmd>UndotreeToggle<cr>", desc = "Toggle Undotree" },
    },
  },

  -- Color highlighter
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

  -- Better fold
  {
    "kevinhwang91/nvim-ufo",
    dependencies = "kevinhwang91/promise-async",
    event = "BufReadPost",
    opts = {
      provider_selector = function() return { "treesitter", "indent" } end,
    },
    init = function()
      vim.o.foldcolumn = "1"
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
    end,
    keys = {
      {
        "zR",
        function() require("ufo").openAllFolds() end,
        desc = "Open all folds",
      },
      {
        "zM",
        function() require("ufo").closeAllFolds() end,
        desc = "Close all folds",
      },
      {
        "zK",
        function() require("ufo").peekFoldedLinesUnderCursor() end,
        desc = "Peek fold",
      },
    },
  },

  {
    "akinsho/toggleterm.nvim",
    opts = {
      size = 15,
      direction = "horizontal",
      shell = vim.o.shell,
      float_opts = { border = "rounded" },
      persist_size = true,
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
      -- NOTE: upstream's nested { "AstroNvim/astrocore", opts = { mappings = ... } }
      -- is intentionally OMITTED. It would be the 100th astrocore fragment and trip
      -- LuaJIT's __index chain limit (lazy meta.lua:267). The <Leader>ts mapping is
      -- declared in plugins/astrocore.lua instead (folds into the existing fragment).
    },
    opts = function(_, opts)
      local term_icon = require("astroui").get_icon "Terminal"
      local actions = require("toggleterm-manager").actions
      return require("astrocore").extend_tbl(opts, {
        titles = { prompt = term_icon .. " Terminals" },
        results = { term_icon = term_icon },
        mappings = {
          n = {
            ["<CR>"] = { action = actions.toggle_term, exit_on_action = true },
            ["r"] = { action = actions.rename_term, exit_on_action = false },
            ["d"] = { action = actions.delete_term, exit_on_action = false },
            ["n"] = { action = actions.create_term, exit_on_action = false },
          },
          i = {
            ["<CR>"] = { action = actions.toggle_term, exit_on_action = true },
            ["<C-r>"] = { action = actions.rename_term, exit_on_action = false },
            ["<C-d>"] = { action = actions.delete_term, exit_on_action = false },
            ["<C-n>"] = { action = actions.create_term, exit_on_action = false },
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

  -- VSCode-like sidebar layout manager
  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    opts = {
      left = {
        {
          title = "Neo-Tree",
          ft = "neo-tree",
          filter = function(buf) return vim.b[buf].neo_tree_source == "filesystem" end,
          size = { height = 0.5 },
        },
        {
          title = "Neo-Tree Symbols",
          ft = "neo-tree",
          filter = function(buf) return vim.b[buf].neo_tree_source == "document_symbols" end,
          pinned = true,
          open = "Neotree position=right document_symbols",
        },
      },
      bottom = {
        { ft = "qf", title = "QuickFix" },
        {
          ft = "help",
          size = { height = 20 },
          filter = function(buf) return vim.bo[buf].buftype == "help" end,
        },
      },
      animate = { enabled = false },
    },
  },

  -- Session persistence (auto-save/restore like VSCode workspaces)
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = { options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" } },
    keys = {
      { "<leader>Ss", function() require("persistence").save() end, desc = "Save session" },
      { "<leader>Sl", function() require("persistence").load() end, desc = "Load session (cwd)" },
      { "<leader>SL", function() require("persistence").load { last = true } end, desc = "Load last session" },
      { "<leader>Sd", function() require("persistence").stop() end, desc = "Don't save session on exit" },
    },
  },
}
