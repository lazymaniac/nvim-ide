return {

  -- [[ EDIT REMOTE AND IN DOCKER ]] ---------------------------------------------------------------
  -- [netman.nvim] - Edit files via SSH or in docker
  -- see: `:h netman`
  {
    'miversen33/netman.nvim',
    event = 'VeryLazy',
    branch = 'v1.15',
    -- Note, you do not need this if you plan on using Netman with any of the
    -- supported UI Tools such as Neo-tree
    -- config = true,
  },
}
