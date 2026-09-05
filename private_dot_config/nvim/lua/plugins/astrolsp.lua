local conform_first_filetypes = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
}

local sql_language_server = vim.fn.exepath "sql-language-server"
local lsp_servers = {
  "lua_ls",
  "basedpyright",
  "gopls",
  "rust_analyzer",
  "ts_ls",
  "angularls",
  "volar",
  "tailwindcss",
  "html",
  "cssls",
  "jsonls",
  "yamlls",
  "bashls",
  "dockerls",
  "terraformls",
  "taplo",
  "zls",
  "elixirls",
  "marksman",
  "cmake",
  "helm_ls",
  "mdx_analyzer",
  "tinymist",
  "intelephense",
}
if sql_language_server ~= "" then table.insert(lsp_servers, "sqlls") end

---@type LazySpec
return {
  "AstroNvim/astrolsp",

  ---@type AstroLSPOpts
  opts = {
    features = {
      autoformat = true,
      codelens = true,
      -- Ative sob demanda com <Leader>uh/<Leader>uH; evita poluição visual
      -- e trabalho extra em todos os buffers LSP.
      inlay_hints = false,
      semantic_tokens = true,
      signature_help = true,
    },
    formatting = {
      format_on_save = {
        enabled = true,
        allow_filetypes = {},
        ignore_filetypes = conform_first_filetypes,
      },
      disabled = {},
      timeout_ms = 2000,
    },
    -- These servers are installed and versioned by mise. Keeping this list
    -- explicit prevents Mason's installed packages from becoming the source
    -- of truth and accidentally enabling formatter LSPs such as stylua.
    servers = lsp_servers,
    handlers = {
      -- stylua is a formatter in this configuration, never a code LSP.
      stylua = false,
      selene = false,
    },
    config = {
      gopls = {
        filetypes = { "go", "gomod", "gowork", "gosum" },
      },
      sqlls = {
        cmd = { sql_language_server, "up", "--method", "stdio" },
      },
    },
    autocmds = {
      lsp_codelens_refresh = {
        cond = function(client)
          return client:supports_method "textDocument/codeLens"
            and vim.tbl_contains({ "go", "java", "rust", "typescript", "typescriptreact" }, vim.bo.filetype)
        end,
        {
          event = { "LspAttach", "BufWritePost" },
          desc = "Refresh code lens after attach/save",
          callback = function(args)
            if not require("astrolsp").config.features.codelens then return end
            vim.defer_fn(function()
              if vim.api.nvim_buf_is_valid(args.buf) then vim.lsp.codelens.refresh { bufnr = args.buf } end
            end, 200)
          end,
        },
      },
      lsp_document_highlight = {
        cond = "textDocument/documentHighlight",
        {
          event = { "CursorHold", "CursorHoldI" },
          desc = "Document Highlighting",
          callback = function() vim.lsp.buf.document_highlight() end,
        },
        {
          event = { "CursorMoved", "CursorMovedI", "BufLeave" },
          desc = "Document Highlighting Clear",
          callback = function() vim.lsp.buf.clear_references() end,
        },
      },
    },
    mappings = {
      n = {
        gl = { function() vim.diagnostic.open_float() end, desc = "Hover diagnostics" },
        gD = {
          function() vim.lsp.buf.declaration() end,
          desc = "Declaration of current symbol",
          cond = "textDocument/declaration",
        },
        ["<Leader>uY"] = {
          function() require("astrolsp.toggles").buffer_semantic_tokens() end,
          desc = "Toggle LSP semantic highlight (buffer)",
          cond = function(client)
            return client:supports_method "textDocument/semanticTokens/full" and vim.lsp.semantic_tokens ~= nil
          end,
        },
      },
    },
  },
}
