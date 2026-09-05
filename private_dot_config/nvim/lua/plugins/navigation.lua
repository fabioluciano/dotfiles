---@type LazySpec
return {
  -- Harpoon (inline: astrocommunity.motion.harpoon usa opts=function em dependency, causa loop)
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      {
        "<Leader><Leader>a",
        function() require("harpoon"):list():add() end,
        desc = "Harpoon add file",
      },
      {
        "<Leader><Leader>e",
        function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end,
        desc = "Harpoon menu",
      },
      {
        "<Leader><Leader>p",
        function() require("harpoon"):list():prev() end,
        desc = "Harpoon prev mark",
      },
      {
        "<Leader><Leader>n",
        function() require("harpoon"):list():next() end,
        desc = "Harpoon next mark",
      },
    },
  },

  {
    "Isrothy/neominimap.nvim",
    cmd = "Neominimap",
    keys = {
      { "<leader>nm", "<cmd>Neominimap Toggle<cr>", desc = "Toggle minimap" },
      { "<leader>nwt", "<cmd>Neominimap WinToggle<cr>", desc = "Toggle minimap (window)" },
      { "<leader>nf", "<cmd>Neominimap Focus<cr>", desc = "Focus minimap" },
    },
    opts = {
      auto_enable = false,
      layout = "float",
      float = {
        minimap_width = 16,
        margin = { right = 1, top = 0, bottom = 0 },
        persist = true,
      },
      delay = 300,
      x_multiplier = 3,
      current_line_position = "center",
      click = {
        enabled = true,
        auto_switch_focus = false,
      },
      exclude_filetypes = {
        "help",
        "bigfile",
        "lazy",
        "mason",
        "neo-tree",
        "TelescopePrompt",
        "Trouble",
        "toggleterm",
        "noice",
        "notify",
      },
      exclude_buftypes = {
        "nofile",
        "nowrite",
        "quickfix",
        "terminal",
        "prompt",
      },
      buf_filter = function(bufnr)
        if vim.api.nvim_buf_get_name(bufnr) == "" or vim.bo[bufnr].buftype ~= "" then return false end
        if require("utils.buffer").is_large(bufnr) then return false end
        local line_count = vim.api.nvim_buf_line_count(bufnr)
        local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ""
        return first_line ~= "" or line_count > 1
      end,
      diagnostic = {
        enabled = true,
        mode = "line",
      },
      git = {
        enabled = true,
        mode = "sign",
      },
      treesitter = {
        enabled = true,
      },
      search = {
        enabled = false,
      },
    },
  },

  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      sources = { "document_symbols", "filesystem" },
      window = {
        width = 50,
        mappings = {
          ["<ScrollWheelLeft>"] = "noop",
          ["<ScrollWheelRight>"] = "noop",
        },
      },
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
        follow_current_file = { enabled = false },
        hijack_netrw_behavior = "disabled",
      },
    },
  },

  {
    "chentoast/marks.nvim",
    event = "VeryLazy",
    opts = { default_mappings = true, signs = true, mappings = {} },
  },

  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = { { "<leader>U", "<cmd>UndotreeToggle<cr>", desc = "Toggle Undotree" } },
  },

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
      vim.o.foldmethod = "expr"
      vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end,
    keys = {
      { "zR", function() require("ufo").openAllFolds() end, desc = "Open all folds" },
      { "zM", function() require("ufo").closeAllFolds() end, desc = "Close all folds" },
      { "zK", function() require("ufo").peekFoldedLinesUnderCursor() end, desc = "Peek fold" },
    },
  },

  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    opts = {
      left = {
        {
          title = "Neo-Tree",
          ft = "neo-tree",
          filter = function(buf) return vim.b[buf].neo_tree_source == "filesystem" end,
          size = { width = 50 },
          pinned = true,
          open = "Neotree position=left filesystem",
        },
        {
          title = "Neo-Tree Symbols",
          ft = "neo-tree",
          filter = function(buf) return vim.b[buf].neo_tree_source == "document_symbols" end,
          pinned = true,
          size = { width = 50 },
          open = "Neotree position=left document_symbols",
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
}
