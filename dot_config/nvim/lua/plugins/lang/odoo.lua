return {
  {
    "nvim-lspconfig",
    init = function()
      vim.filetype.add({
        filename = {
          [".odoo_lsp"] = "json",
        },
      })
    end,
    opts = {
      servers = {
        odoo_lsp = {},
      },
    },
  },
  -- {
  --   "odoo/odoo-neovim",
  --   ft = { "python", "xml" },
  --   init = function()
  --     local odoo_ls_name = "odoo_ls"
  --     vim.lsp.config(odoo_ls_name, {
  --       cmd = {
  --         -- Path to the odoo_ls_server binary
  --         vim.fn.expand("$HOME/.local/share/nvim/odoo/odoo_ls_server"),
  --         "--config-path",
  --         vim.fn.expand("$HOME/odools.toml"),
  --       },
  --     })
  --     vim.lsp.enable(odoo_ls_name)
  --   end,
  -- },
}
