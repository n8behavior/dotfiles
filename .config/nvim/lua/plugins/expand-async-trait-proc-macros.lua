return {
  "mrcjkb/rustaceanvim",
  opts = {
    server = {
      settings = {
        ["rust-analyzer"] = {
          procMacro = {
            enable = true,
            -- Remove async-trait from ignored
            ignored = {
              -- Optionally leave others as you want
              ["napi-derive"] = { "napi" },
              ["async-recursion"] = { "async_recursion" },
              -- "async-trait" key omitted means async_trait *will* be expanded!
            },
          },
        },
      },
    },
  },
}
