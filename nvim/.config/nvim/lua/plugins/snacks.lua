-- Override / configure snacks.nvim (pulled in by LazyVim as a core dependency).
-- See https://github.com/folke/snacks.nvim for all available options.
return {
  "folke/snacks.nvim",
  -- picker + explorer are enabled/wired up by the LazyVim extras
  -- (snacks_picker, snacks_explorer) in lazyvim.json. This file is just
  -- for extra module toggles / overrides. Uncomment any you want:
  opts = {
    -- dashboard = { enabled = true },
    -- notifier = { enabled = true },
    -- indent = { enabled = true },
    -- scroll = { enabled = false },
    -- scope = { enabled = true },
    -- words = { enabled = true },
  },
}
