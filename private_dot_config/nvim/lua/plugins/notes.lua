---@type LazySpec
return {
  {
    "obsidian-nvim/obsidian.nvim",
    opts = {
      workspaces = {
        { name = "study", path = vim.fn.expand "~/Obsidian/study" },
        { name = "work", path = vim.fn.expand "~/Obsidian/work" },
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
}
