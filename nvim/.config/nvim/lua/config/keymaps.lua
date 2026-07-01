-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Toggle the completion popup that appears automatically as you type.
-- Off by default (see plugins/blink.lua). <leader>uk flips it live, and it
-- shows up in the `Space u` (UI toggles) which-key menu.
Snacks.toggle({
  name = "Completion (auto-popup)",
  get = function()
    return vim.g.completion_auto_show == true
  end,
  set = function(state)
    vim.g.completion_auto_show = state
  end,
}):map("<leader>uk")
