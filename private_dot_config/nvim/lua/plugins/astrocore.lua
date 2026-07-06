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
      virtual_text = true,
      underline = true,
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
        -- Mouse support
        mouse = "a",
        mousescroll = "ver:3,hor:3",
        -- Scrolling
        scrolloff = 8,
        sidescrolloff = 8,
      },
      g = {},
    },
    mappings = {
      n = {
        -- AI / OpenCode
        ["<Leader>o"]  = { desc = "󱙺 OpenCode" },
        ["<Leader>e"]  = { "<cmd>Neotree toggle reveal<cr>", desc = " Toggle Explorer" },

        -- Core actions
        ["<Leader>oa"] = { function() require("opencode").ask("@this: ") end,                          desc = "Ask" },
        ["<Leader>os"] = { function() require("opencode").select() end,                                desc = "Select action" },
        ["<Leader>ot"] = {
          function()
            -- Find an existing opencode terminal window
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              local buf = vim.api.nvim_win_get_buf(win)
              local name = vim.api.nvim_buf_get_name(buf)
              if name:match("term://.*opencode") then
                -- Window visible: close it
                vim.api.nvim_win_close(win, false)
                return
              end
            end
            -- Find a hidden opencode terminal buffer
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              local name = vim.api.nvim_buf_get_name(buf)
              if name:match("term://.*opencode") and vim.api.nvim_buf_is_loaded(buf) then
                -- Reopen in a vertical split
                vim.cmd("vsplit")
                vim.api.nvim_win_set_buf(0, buf)
                vim.cmd("wincmd p")
                return
              end
            end
            -- No opencode terminal exists yet: start one
            vim.cmd("vsplit term://opencode | wincmd p")
          end,
          desc = "Toggle OpenCode",
        },

        -- Prompts
        ["<Leader>op"] = { desc = "󰙎 Prompts" },
        ["<Leader>opf"] = { function() require("opencode").prompt("fix") end,                          desc = "Fix diagnostics" },
        ["<Leader>ope"] = { function() require("opencode").prompt("explain") end,                      desc = "Explain" },
        ["<Leader>opr"] = { function() require("opencode").prompt("review") end,                       desc = "Review" },
        ["<Leader>opd"] = { function() require("opencode").prompt("document") end,                     desc = "Document" },
        ["<Leader>opt"] = { function() require("opencode").prompt("test") end,                         desc = "Add tests" },
        ["<Leader>opo"] = { function() require("opencode").prompt("optimize") end,                     desc = "Optimize" },
        ["<Leader>opR"] = { function() require("opencode").prompt("refactor") end,                     desc = "Refactor" },
        ["<Leader>ops"] = { function() require("opencode").prompt("security") end,                     desc = "Security review" },
        ["<Leader>opD"] = { function() require("opencode").prompt("diagnostics") end,                  desc = "Explain diagnostics" },
        ["<Leader>opg"] = { function() require("opencode").prompt("diff") end,                         desc = "Review git diff" },
        ["<Leader>opx"] = { function() require("opencode").prompt("debug") end,                        desc = "Add debug logging" },

        -- Session
        ["<Leader>oS"] = { desc = " Session" },
        ["<Leader>oSn"] = { function() require("opencode").command("session.new") end,                 desc = "New session" },
        ["<Leader>oSl"] = { function() require("opencode").command("session.list") end,                desc = "List sessions" },
        ["<Leader>oSs"] = { function() require("opencode").command("session.select") end,              desc = "Select session" },
        ["<Leader>oSi"] = { function() require("opencode").command("session.interrupt") end,           desc = "Interrupt" },
        ["<Leader>oSc"] = { function() require("opencode").command("session.compact") end,             desc = "Compact context" },
        ["<Leader>oSu"] = { function() require("opencode").command("session.undo") end,                desc = "Undo" },
        ["<Leader>oSr"] = { function() require("opencode").command("session.redo") end,                desc = "Redo" },
        ["<Leader>oSh"] = { function() require("opencode").command("session.share") end,               desc = "Share session" },

        -- Agent & navigation
        ["<Leader>oA"] = { function() require("opencode").command("agent.cycle") end,                  desc = "Cycle agent" },
        ["<S-C-u>"]    = { function() require("opencode").command("session.half.page.up") end,         desc = "OpenCode scroll up" },
        ["<S-C-d>"]    = { function() require("opencode").command("session.half.page.down") end,       desc = "OpenCode scroll down" },

        -- Operator (go / goo) — motion e line
        -- <Leader>or enters operator-pending mode: wait for a motion/text-object.
        -- <Leader>oo does the same but pre-sends "_" (current line) as the motion,
        -- so it acts on the line under the cursor in one keystroke.
        ["<Leader>or"] = { function() return require("opencode").operator("@this ") end, expr = true, desc = "Send range to OpenCode" },
        ["<Leader>oo"] = { function() return require("opencode").operator("@this ") .. "_" end, expr = true, desc = "Send line to OpenCode" },

        -- Run / Tasks (overseer)
        ["<Leader>R"] = { desc = "󱓞 Run/Tasks" },
        ["<Leader>Rr"] = { "<cmd>OverseerRun<cr>", desc = "Run task" },
        ["<Leader>Rt"] = { "<cmd>OverseerToggle<cr>", desc = "Toggle task list" },

        -- Test (neotest) — under <Leader>t to avoid collision with AstroNvim v6 terminal prefix
        ["<Leader>tT"] = { desc = "󰙨 Test" },
        ["<Leader>tTt"] = { function() require("neotest").run.run(vim.fn.expand "%") end, desc = "Test file" },
        ["<Leader>tTn"] = { function() require("neotest").run.run() end, desc = "Test nearest" },
        ["<Leader>tTs"] = { function() require("neotest").summary.toggle() end, desc = "Toggle summary" },

        -- Git extras (diffview / codediff / octo)
        ["<Leader>gD"] = { "<cmd>DiffviewOpen<cr>",  desc = "Diffview open" },
        ["<Leader>gd"] = { "<cmd>CodeDiff<cr>",      desc = "CodeDiff open" },
        ["<Leader>gO"] = { "<cmd>Octo pr list<cr>",  desc = "Octo: list PRs" },

        -- Misc
        ["<Leader>z"] = { "<cmd>ZenMode<cr>", desc = "Zen mode" },
        ["<Leader>tM"] = { "<cmd>Telescope toggleterm_manager<cr>", desc = "Search Toggleterms" },
        -- Disable community pack's <Leader>ts (toggleterm-manager) — we use <Leader>tM instead
        ["<Leader>ts"] = false,
        ["<Leader>uo"] = { "<cmd>Neotree document_symbols<cr>", desc = "Outline (document symbols)" },

        ["<Leader>Ss"] = { function() require("resession").save() end,   desc = "Save session" },
        ["<Leader>Sl"] = { function() require("resession").load() end,   desc = "Load session (cwd)" },
        ["<Leader>SL"] = { function() require("resession").load("last") end, desc = "Load last session" },
        ["<Leader>Sd"] = { function() require("resession").detach() end, desc = "Detach session (stop auto-save)" },
      },
      v = {
        -- OpenCode prompts (visual mode — operate on selection)
        ["<Leader>ope"] = { function() require("opencode").prompt("explain") end,  desc = "Explain selection" },
        ["<Leader>opr"] = { function() require("opencode").prompt("review") end,   desc = "Review selection" },
      },
    },
    autocmds = {
      -- Enable spell only for text files (markdown, text, gitcommit, etc.)
      spell_text_files = {
        {
          event = "FileType",
          pattern = { "markdown", "text", "gitcommit", "plaintex", "tex", "rst", "asciidoc" },
          callback = function()
            vim.opt_local.spell = true
          end,
          desc = "Enable spell checking for text files",
        },
      },
      -- Enable spell only in comments for code files using Treesitter
      spell_comments = {
        {
          event = "FileType",
          pattern = {
            "lua", "python", "javascript", "typescript", "typescriptreact", "javascriptreact",
            "go", "rust", "c", "cpp", "java", "php", "ruby", "sh", "bash", "zsh", "yaml", "toml",
          },
          callback = function()
            vim.opt_local.spell = true
            -- Only check spelling in comments and strings via treesitter
            vim.opt_local.spelloptions:append("noplainbuffer")
          end,
          desc = "Enable spell checking only in comments for code files",
        },
      },
      -- VSCode-like layout: neo-tree left | empty buffer center | terminal bottom
      vscode_layout = {
        {
          event = "VimEnter",
          desc = "VSCode-like layout when a directory is passed as argument",
          nested = true,
          callback = function()
            if vim.fn.argc(-1) == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
              vim.schedule(function()
                vim.cmd.cd(vim.fn.argv(0))
                -- enew first: replaces any netrw/directory buffer so neo-tree
                -- opens as a narrow left split instead of filling the whole screen
                vim.cmd("enew")
                vim.cmd("Neotree filesystem left")
                vim.cmd("wincmd l")
                vim.cmd("ToggleTerm direction=horizontal")
                vim.cmd("wincmd p")
              end)
            end
          end,
        },
      },
    },
  },
}
