-- ╭──────────────────────────────────────────────────────────╮
-- │                    AstroCommunity Plugins                 │
-- │              Community-maintained plugin configs          │
-- ╰──────────────────────────────────────────────────────────╯

---@type LazySpec
return {
  "AstroNvim/astrocommunity",

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Appearance                          │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.color.twilight-nvim" },
  { import = "astrocommunity.colorscheme.tokyonight-nvim" },
  {
    "folke/tokyonight.nvim",
    opts = {
      on_highlights = function(hl, c)
        hl.SpellBad = { bg = "#3d2026", fg = "#f7768e", underline = true }
        hl.SpellCap = { bg = "#3d3520", fg = "#e0af68", underline = true }
        hl.SpellLocal = { bg = "#203040", fg = "#7aa2f7", underline = true }
        hl.SpellRare = { bg = "#302040", fg = "#bb9af7", underline = true }
      end,
    },
  },
  { import = "astrocommunity.bars-and-lines.dropbar-nvim" },
  { import = "astrocommunity.bars-and-lines.vim-illuminate" },
  { import = "astrocommunity.icon.mini-icons" },

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Completion                          │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.completion.blink-cmp" },
  { import = "astrocommunity.completion.blink-cmp-git" },
  { import = "astrocommunity.ai.opencode-nvim" },

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Code Runner                         │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.code-runner.overseer-nvim" },
  { import = "astrocommunity.code-runner.sniprun" },

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Debugging                           │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.debugging.nvim-dap-virtual-text" },
  { import = "astrocommunity.debugging.telescope-dap-nvim" },
  { import = "astrocommunity.debugging.persistent-breakpoints-nvim" },
  { import = "astrocommunity.debugging.nvim-dap-view" },

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Diagnostics                         │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.diagnostics.trouble-nvim" },

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Editing Support                     │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.editing-support.comment-box-nvim" },
  { import = "astrocommunity.editing-support.conform-nvim" },
  { import = "astrocommunity.editing-support.multicursors-nvim" },
  { import = "astrocommunity.editing-support.nvim-regexplainer" },
  { import = "astrocommunity.editing-support.todo-comments-nvim" },
  { import = "astrocommunity.editing-support.vim-move" },
  { import = "astrocommunity.editing-support.rainbow-delimiters-nvim" },
  { import = "astrocommunity.editing-support.yanky-nvim" },
  { import = "astrocommunity.editing-support.refactoring-nvim" },
  { import = "astrocommunity.editing-support.zen-mode-nvim" },
  { import = "astrocommunity.editing-support.nvim-treesitter-context" },

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Fuzzy Finder                        │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.search.grug-far-nvim" },
  { import = "astrocommunity.fuzzy-finder.telescope-zoxide" },

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Git                                 │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.git.octo-nvim" },
  { import = "astrocommunity.git.neogit" },
  { import = "astrocommunity.git.diffview-nvim" },
  { import = "astrocommunity.git.git-blame-nvim" }, -- kept this one (more features than blame-nvim)
  { import = "astrocommunity.git.codediff-nvim" },

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Indent                              │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.indent.indent-blankline-nvim" },

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    LSP                                 │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.lsp.nvim-lint" },
  { import = "astrocommunity.lsp.garbage-day-nvim" },
  { import = "astrocommunity.lsp.inc-rename-nvim" },

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Markdown & LaTeX                    │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.markdown-and-latex.markdown-preview-nvim" },

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Motion                              │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.motion.flash-nvim" },
  { import = "astrocommunity.motion.nvim-surround" },

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Language Packs                      │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.pack.angular" },
  { import = "astrocommunity.pack.astro" },
  { import = "astrocommunity.pack.bash" },
  { import = "astrocommunity.pack.go" },
  { import = "astrocommunity.pack.helm" },
  { import = "astrocommunity.pack.html-css" },
  { import = "astrocommunity.pack.java" },
  { import = "astrocommunity.pack.just" },
  { import = "astrocommunity.pack.json" },
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.mdx" },
  { import = "astrocommunity.pack.php" },
  { import = "astrocommunity.pack.python" },
  { import = "astrocommunity.pack.rust" },
  { import = "astrocommunity.pack.sql" },
  { import = "astrocommunity.pack.svelte" },
  { import = "astrocommunity.pack.terraform" },
  { import = "astrocommunity.pack.toml" },
  { import = "astrocommunity.pack.typescript-all-in-one" },
  { import = "astrocommunity.pack.vue" },
  { import = "astrocommunity.pack.xml" },
  { import = "astrocommunity.pack.yaml" },
  { import = "astrocommunity.pack.chezmoi" },
  { import = "astrocommunity.pack.cmake" },
  { import = "astrocommunity.pack.docker" },
  { import = "astrocommunity.pack.nix" },

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Note-taking                         │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.note-taking.obsidian-nvim" },
  {
    "epwalsh/obsidian.nvim",
    opts = {
      workspaces = {
        { name = "study", path = "~/Obsidian/study" },
        { name = "work", path = "~/Obsidian/work" },
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

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Docker                              │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.docker.lazydocker" },

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Test                                │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.test.neotest" },
  { import = "astrocommunity.test.nvim-coverage" },
  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Project                             │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.project.project-nvim" },

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Recipes                             │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.recipes.vscode" },
  { import = "astrocommunity.recipes.vscode-icons" },
  { import = "astrocommunity.recipes.neovide" },
  { import = "astrocommunity.recipes.telescope-lsp-mappings" },

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Scrolling                           │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.scrolling.mini-animate" },

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Syntax                              │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.syntax.vim-easy-align" },
  { import = "astrocommunity.syntax.hlargs-nvim" },

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Terminal Integration                │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.terminal-integration.vim-tmux-yank" },
  { import = "astrocommunity.terminal-integration.flatten-nvim" },
  { import = "astrocommunity.terminal-integration.vim-tmux-navigator" },

  -- ╭──────────────────────────────────────────────────────╮
  -- │                    Split and Window                    │
  -- ╰──────────────────────────────────────────────────────╯
  { import = "astrocommunity.split-and-window.neominimap-nvim" },
  { "Isrothy/neominimap.nvim", opts = { auto_enable = true } },

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Utility                             │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.utility.noice-nvim" },
  { import = "astrocommunity.utility.telescope-live-grep-args-nvim" },

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Programming Language Support        │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.programming-language-support.kulala-nvim" },

  -- ╭────────────────────────────────────────────────────────╮
  -- │                    Workflow                            │
  -- ╰────────────────────────────────────────────────────────╯
  { import = "astrocommunity.workflow.precognition-nvim" },
}
