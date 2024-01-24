return {
  name = 'Maven Get Active Profiles',
  builder = function()
    return {
      cmd = { 'mvn' },
      args = { 'help:active-profiles' },
    }
  end,
  desc = 'mvn help:active-profiles',
  condition = {
    filetype = { 'java', 'xml' },
  },
}
