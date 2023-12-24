return {

  -- Should be able to connect to external hosts via SSH
  {
    'miversen33/netman.nvim',
    lazy = false,
    event = 'VeryLazy',
    branch = 'v1.15',
    -- Note, you do not need this if you plan on using Netman with any of the
    -- supported UI Tools such as Neo-tree
    -- config = true,
  },
}
