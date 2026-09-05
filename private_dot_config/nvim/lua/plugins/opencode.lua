local opencode_command = { "opencode", "--port" }
local opencode_shell_command = table.concat(opencode_command, " ")
local available = vim.fn.executable(opencode_command[1]) == 1

if not available and #vim.api.nvim_list_uis() > 0 then
  vim.schedule(
    function()
      vim.notify_once(
        "OpenCode desativado: instale o executável 'opencode' globalmente para habilitar plugin e mappings.",
        vim.log.levels.WARN
      )
    end
  )
end

local function call(method, argument)
  return function() require("opencode")[method](argument) end
end

---@type LazySpec
return {
  {
    "NickvanDyke/opencode.nvim",
    enabled = available,
    keys = {
      { "<Leader>oa", call("ask", "@this: "), desc = "OpenCode ask" },
      { "<Leader>os", call "select", desc = "OpenCode select action" },
      {
        "<Leader>ot",
        function()
          require("snacks.terminal").toggle(opencode_shell_command, { win = { position = "right", enter = false } })
        end,
        desc = "Toggle OpenCode",
      },
      { "<Leader>opf", call("prompt", "fix"), desc = "Fix diagnostics" },
      { "<Leader>ope", call("prompt", "explain"), mode = { "n", "x" }, desc = "Explain" },
      { "<Leader>opr", call("prompt", "review"), mode = { "n", "x" }, desc = "Review" },
      { "<Leader>opd", call("prompt", "document"), desc = "Document" },
      { "<Leader>opt", call("prompt", "test"), desc = "Add tests" },
      { "<Leader>opo", call("prompt", "optimize"), desc = "Optimize" },
      { "<Leader>opR", call("prompt", "refactor"), desc = "Refactor" },
      { "<Leader>ops", call("prompt", "security"), desc = "Security review" },
      { "<Leader>opD", call("prompt", "diagnostics"), desc = "Explain diagnostics" },
      { "<Leader>opg", call("prompt", "diff"), desc = "Review git diff" },
      { "<Leader>opx", call("prompt", "debug"), desc = "Add debug logging" },
      { "<Leader>oSn", call("command", "session.new"), desc = "New session" },
      { "<Leader>oSl", call("command", "session.list"), desc = "List sessions" },
      { "<Leader>oSs", call("command", "session.select"), desc = "Select session" },
      { "<Leader>oSi", call("command", "session.interrupt"), desc = "Interrupt" },
      { "<Leader>oSc", call("command", "session.compact"), desc = "Compact context" },
      { "<Leader>oSu", call("command", "session.undo"), desc = "Undo" },
      { "<Leader>oSr", call("command", "session.redo"), desc = "Redo" },
      { "<Leader>oSh", call("command", "session.share"), desc = "Share session" },
      { "<Leader>oA", call("command", "agent.cycle"), desc = "Cycle agent" },
      {
        "<Leader>or",
        function() return require("opencode").operator "@this " end,
        expr = true,
        desc = "Send range to OpenCode",
      },
      {
        "<Leader>oo",
        function() return require("opencode").operator "@this " .. "_" end,
        expr = true,
        desc = "Send line to OpenCode",
      },
    },
    config = function(_, opts) vim.g.opencode_opts = vim.tbl_deep_extend("force", vim.g.opencode_opts or {}, opts) end,
    opts = {
      server = {
        start = function()
          require("snacks.terminal").open(opencode_shell_command, { win = { position = "right", enter = false } })
        end,
      },
      events = {
        enabled = true,
        reload = true,
        permissions = { enabled = true, idle_delay_ms = 1000, edits = { enabled = true } },
      },
      prompts = {
        ask = { prompt = "", submit = true, ask = true },
        diagnostics = { prompt = "Explain @diagnostics", submit = true },
        diff = { prompt = "Review the following git diff for correctness: @diff", submit = true },
        explain = { prompt = "Explain @this and its context", submit = true },
        review = { prompt = "Review @this for correctness and readability", submit = true },
        document = { prompt = "Add comments documenting @this", submit = true },
        fix = { prompt = "Fix @diagnostics", submit = true },
        implement = { prompt = "Implement @this", submit = true },
        optimize = { prompt = "Optimize @this for performance and readability", submit = true },
        test = { prompt = "Add tests for @this", submit = true },
        refactor = { prompt = "Refactor @this to be more maintainable", submit = true },
        security = { prompt = "Review @this for security vulnerabilities", submit = true },
        debug = { prompt = "Add debug logging to @this", ask = true, submit = false },
      },
    },
  },
}
