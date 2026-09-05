---@type LazySpec
return {
  "AstroNvim/astrocore",
  opts = {
    features = {
      large_buf = { size = 1024 * 500, lines = 10000 },
      autopairs = false,
      diagnostics_mode = 3,
      highlighturl = true,
      notifications = true,
    },
    sessions = {
      autosave = { last = true, cwd = true },
      ignore = {
        filetypes = { "gitcommit", "gitrebase" },
        buftypes = { "terminal" },
      },
    },
    diagnostics = {
      virtual_text = { spacing = 2, source = "if_many" },
      underline = true,
      severity_sort = true,
      update_in_insert = false,
    },
    options = {
      opt = {
        updatetime = 100,
        conceallevel = 2,
        title = true,
        splitbelow = true,
        splitright = true,
        diffopt = vim.opt.diffopt + "vertical",
        linebreak = true,
        cursorline = true,
        breakindent = true,
        list = true,
        listchars = {
          space = "⋅",
          eol = "↲",
          tab = "󰌒",
          trail = "·",
          nbsp = "␣",
          extends = "…",
          precedes = "…",
        },
        relativenumber = false,
        number = true,
        spell = false, -- Disabled globally, enabled per filetype
        spelllang = { "en", "pt" },
        spelloptions = "camel", -- Check camelCase words separately
        signcolumn = "yes:1",
        wrap = true,
        tabstop = 2,
        mouse = "a",
        mousescroll = "ver:3,hor:3",
        scrolloff = 8,
        sidescrolloff = 8,
      },
      g = {},
    },
    mappings = {
      n = {
        ["<Leader>e"] = { "<cmd>Neotree toggle reveal<cr>", desc = " Toggle Explorer" },
        ["<Leader>ef"] = {
          function()
            if vim.bo.filetype == "neo-tree" then
              vim.cmd.wincmd "p"
            else
              vim.cmd.Neotree "focus"
            end
          end,
          desc = "Toggle Explorer Focus",
        },

        ["<Leader>R"] = { desc = "󱓞 Run/Tasks" },
        ["<Leader>Rr"] = { "<cmd>OverseerRun<cr>", desc = "Run task" },
        ["<Leader>Rt"] = { "<cmd>OverseerToggle<cr>", desc = "Toggle task list" },
        ["<Leader>rf"] = { function() require("astrocore").rename_file() end, desc = "Rename file" },

        -- Test (neotest) — under <Leader>t to avoid collision with AstroNvim v6 terminal prefix
        ["<Leader>tT"] = { desc = "󰙨 Test" },
        ["<Leader>tTt"] = { function() require("neotest").run.run(vim.fn.expand "%") end, desc = "Test file" },
        ["<Leader>tTn"] = { function() require("neotest").run.run() end, desc = "Test nearest" },
        ["<Leader>tTs"] = { function() require("neotest").summary.toggle() end, desc = "Toggle summary" },

        ["<Leader>gD"] = { "<cmd>DiffviewOpen<cr>", desc = "Diffview open" },
        ["<Leader>gO"] = { "<cmd>Octo pr list<cr>", desc = "Octo: list PRs" },

        ["<Leader>z"] = { function() require("snacks").zen() end, desc = "Zen mode" },
        ["<Leader>uZ"] = false,
        ["<Leader>uo"] = { "<cmd>Neotree document_symbols<cr>", desc = "Outline (document symbols)" },

        ["<Leader>Ss"] = { function() require("resession").save() end, desc = "Save session" },
        ["<Leader>Sl"] = { function() require("resession").load() end, desc = "Load session (cwd)" },
        ["<Leader>SL"] = { function() require("resession").load "last" end, desc = "Load last session" },
        ["<Leader>Sd"] = { function() require("resession").detach() end, desc = "Detach session (stop auto-save)" },
      },
      v = {},
    },
    autocmds = {
      -- One debounced lint pipeline; skip special and large buffers.
      auto_lint = {
        {
          event = { "BufWritePost", "BufReadPost", "InsertLeave" },
          desc = "Lint after meaningful editing boundaries",
          callback = function(args)
            if
              not package.loaded["lint"]
              or vim.bo[args.buf].buftype ~= ""
              or require("utils.buffer").is_large(args.buf)
            then
              return
            end
            vim.b[args.buf].lint_generation = (vim.b[args.buf].lint_generation or 0) + 1
            local generation = vim.b[args.buf].lint_generation
            vim.defer_fn(function()
              if vim.api.nvim_buf_is_valid(args.buf) and vim.b[args.buf].lint_generation == generation then
                require("lint").try_lint(nil, { bufnr = args.buf })
              end
            end, 250)
          end,
        },
      },
      -- Enable spell only for text files (markdown, text, gitcommit, etc.)
      spell_text_files = {
        {
          event = "FileType",
          pattern = { "markdown", "text", "gitcommit", "plaintex", "tex", "rst", "asciidoc" },
          callback = function() vim.opt_local.spell = true end,
          desc = "Enable spell checking for text files",
        },
      },
      -- Enable spell only in comments for code files using Treesitter
      spell_comments = {
        {
          event = "FileType",
          pattern = {
            "lua",
            "python",
            "javascript",
            "typescript",
            "typescriptreact",
            "javascriptreact",
            "go",
            "rust",
            "c",
            "cpp",
            "java",
            "php",
            "ruby",
            "sh",
            "bash",
            "zsh",
            "yaml",
            "toml",
          },
          callback = function()
            vim.opt_local.spell = true
            -- Only check spelling in comments and strings via treesitter
            vim.opt_local.spelloptions:append "noplainbuffer"
          end,
          desc = "Enable spell checking only in comments for code files",
        },
      },
      -- Opening a directory keeps startup light: only Neo-tree opens.
      directory_layout = {
        {
          event = "VimEnter",
          desc = "Open Neo-tree when a directory is passed",
          nested = true,
          callback = function()
            if vim.fn.argc(-1) == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
              vim.schedule(function()
                vim.cmd.cd(vim.fn.argv(0))
                vim.cmd.enew()
                vim.cmd "Neotree filesystem left"
              end)
            end
          end,
        },
      },
    },
  },
}
