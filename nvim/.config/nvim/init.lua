vim.filetype.add({
  extension = {
    mdx = "mdx",
  }
})

vim.treesitter.language.register("markdown", "mdx")

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
