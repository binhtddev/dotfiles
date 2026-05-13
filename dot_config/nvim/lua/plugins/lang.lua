return {
  -- { import = "plugins.lang.gherkin" },
  { import = "plugins.lang.json" },
  { import = "plugins.lang.rust" },
  { import = "plugins.lang.moonbit" },
  {
    "nvim-treesitter",
    opts = {
      ensure_installed = {
        "css",
        "editorconfig",
        "html",
        "make",
        "kdl",
        "mermaid",
        -- "superhtml",
        -- "ziggy",
      },
    },
  },
  {
    "bezhermoso/tree-sitter-ghostty",
    build = "make nvim_install",
    ft = "ghostty",
  },
  {
    "nvim-lspconfig",
    opts = {
      inlay_hints = {
        enabled = false, -- This disables them globally in LazyVim
      },
      diagnostics = {
        float = {
          border = "rounded",
        },
      },
      servers = {
        cssls = {},
        html = {},
        unocss = {
          root_dir = function(fname)
            return require("lspconfig.util").root_pattern("uno.config.ts")(fname)
          end,
        },
      },
    },
  },
  {
    "nvim-lspconfig",
    opts = function(_, opts)
      if opts.servers and opts.servers["*"] and opts.servers["*"].keys then
        opts.servers["*"].keys = vim.tbl_filter(function(key)
          return key[1] ~= "<c-k>"
        end, opts.servers["*"].keys)
      end
    end,
  },
  {
    "conform.nvim",
    opts = {
      -- formatters_by_ft = {
      --   nix = { "alejandra" },
      -- },
    },
  },
  {
    "nvim-lint",
    optional = true,
    opts = function(_, opts)
      if opts.linters_by_ft and opts.linters_by_ft.markdown then
        opts.linters_by_ft.markdown = {}
      end
    end,
  },
  {
    "nvim-lspconfig",
    opts = function(_, opts)
      local ensure_installed = {
        -- astro = true,
        -- tailwindcss = true,
        -- unocss = true,
        -- volar = true,
        -- vtsls = true,
      }
      for server, server_opts in pairs(opts.servers) do
        if type(server_opts) == "table" and not ensure_installed[server] then
          server_opts.mason = false
        end
      end

      local disabled_map = {
        formatting = {
          methods = {
            ["textDocument/formatting"] = true,
            ["textDocument/rangeFormatting"] = true,
          },
          clients = {
            jsonls = true,
            lua_ls = true,
          },
        },
      }
      local origin_supports_method = vim.lsp.client.supports_method
      vim.lsp.client.supports_method = function(self_client, method, ...)
        if disabled_map.formatting.methods[method] and disabled_map.formatting.clients[self_client.name] then
          return false
        end
        return origin_supports_method(self_client, method, ...)
      end
    end,
  },
  {
    "mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = {
        -- "markdown-toc",
      }
    end,
  },
}
