-- Completion tuning: don't pop the menu up automatically while typing.
-- Ask for it on demand with <C-space> (Ctrl + Space).
--
-- The auto-popup is controlled by a live flag (vim.g.completion_auto_show) so it
-- can be toggled on/off with a keymap (see keymaps.lua -> <leader>uk) without a
-- restart. Default is off (nil == false).
return {
  "saghen/blink.cmp",
  opts = {
    completion = {
      menu = {
        auto_show = function()
          return vim.g.completion_auto_show == true
        end,
      },
    },
  },
}
