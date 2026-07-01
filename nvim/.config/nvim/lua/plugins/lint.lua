-- markdownlint-cli2 lints stdin without a real file path, so it can't walk
-- up parent directories to find a config the way it does for on-disk files.
-- Point it at a fixed config explicitly so rules like MD013 apply everywhere.
return {
  "mfussenegger/nvim-lint",
  opts = {
    linters = {
      ["markdownlint-cli2"] = {
        prepend_args = { "--config", vim.fn.expand("~/.markdownlint.jsonc") },
      },
    },
  },
}
