local bookmarks_file = vim.fn.stdpath("data") .. "/bookmarks.json"

local function load_bookmarks()
  local ok, file = pcall(io.open, bookmarks_file, "r")
  if not ok or not file then return {} end
  local content = file:read("*a")
  file:close()
  return vim.fn.json_decode(content) or {}
end

local function save_bookmarks(bookmarks)
  local ok, file = pcall(io.open, bookmarks_file, "w")
  if not ok or not file then return end
  file:write(vim.fn.json_encode(bookmarks))
  file:close()
end

local function add_bookmark()
  local cwd = vim.fn.getcwd()
  local bookmarks = load_bookmarks()
  
  for _, b in ipairs(bookmarks) do
    if b == cwd then
      vim.notify("Já está nos bookmarks: " .. cwd, vim.log.levels.WARN)
      return
    end
  end
  
  table.insert(bookmarks, cwd)
  save_bookmarks(bookmarks)
  vim.notify("Adicionado aos bookmarks: " .. cwd, vim.log.levels.INFO)
end

local function remove_bookmark()
  local cwd = vim.fn.getcwd()
  local bookmarks = load_bookmarks()
  local new_bookmarks = {}
  
  for _, b in ipairs(bookmarks) do
    if b ~= cwd then
      table.insert(new_bookmarks, b)
    end
  end
  
  save_bookmarks(new_bookmarks)
  vim.notify("Removido dos bookmarks: " .. cwd, vim.log.levels.INFO)
end

local function open_bookmarks()
  local bookmarks = load_bookmarks()
  if #bookmarks == 0 then
    vim.notify("Nenhum bookmark salvo", vim.log.levels.WARN)
    return
  end
  
  vim.ui.select(bookmarks, {
    prompt = "Bookmarks:",
    format_item = function(item)
      return vim.fn.fnamemodify(item, ":~")
    end,
  }, function(choice)
    if choice then
      vim.cmd("cd " .. vim.fn.fnameescape(choice))
      require("snacks").explorer()
    end
  end)
end

return {
  "folke/snacks.nvim",
  -- NOTE: use opts function to merge with AstroNvim's built-in snacks config
  -- (AstroNvim v6 ships snacks.nvim core; a flat `opts = {}` would override it)
  opts = function(_, opts)
    opts.dashboard = vim.tbl_deep_extend("force", opts.dashboard or {}, {
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        function()
          local bookmarks = load_bookmarks()
          if #bookmarks == 0 then return nil end

          local items = {}
          for _, dir in ipairs(bookmarks) do
            table.insert(items, {
              icon = " ",
              desc = vim.fn.fnamemodify(dir, ":~"),
              action = function()
                vim.cmd("cd " .. dir)
                require("snacks").explorer()
              end,
            })
          end

          return {
            title = "Bookmarks",
            padding = 1,
            items = items,
          }
        end,
        { section = "startup" },
      },
    })
    return opts
  end,
  keys = {
    { "<leader>Ba", add_bookmark, desc = "Add Bookmark" },
    { "<leader>Br", remove_bookmark, desc = "Remove Bookmark" },
    { "<leader>Bd", open_bookmarks, desc = "Open Bookmarks" },
  },
}
