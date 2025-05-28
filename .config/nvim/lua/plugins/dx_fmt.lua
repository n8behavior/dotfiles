-- ~/.config/nvim/lua/plugins/dx_fmt.lua
return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    local util = require("conform.util")

    opts.formatters_by_ft = opts.formatters_by_ft or {}
    opts.formatters_by_ft.rust = { "rustfmt", "dioxus" }

    opts.formatters = vim.tbl_deep_extend("force", opts.formatters or {}, {
      dioxus = {
        command = util.find_executable({ "dx" }, "dx"),
        args = { "fmt" },
        stdin = false,
      },
    })
  end,
}
