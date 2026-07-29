return {
  'dmtrKovalenko/fff.nvim',
  tag = 'v0.10.1',
  build = function()
    require("fff.download").download_or_build_binary()
  end,
  opts = {
    debug = {
      enabled = true,
      show_scores = true,
    },
  },
  lazy = false,
  keys = {
    {
      "<leader>f",
      function() require('fff').find_files() end,
      desc = 'FFFind files',
    },
    {
      "<leader>/",
      function() require('fff').live_grep() end,
      desc = 'LiFFFe grep',
    },
    {
      "<leader>cc",
      function() require('fff').live_grep({ query = vim.fn.expand("<cword>") }) end,
      desc = 'Search current word',
    },
  },
}
