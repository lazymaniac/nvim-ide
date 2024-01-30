return {
  name = 'Maven Get All Profiles',
  builder = function()
    return {
      cmd = { 'mvn' },
      args = { 'help:all-profiles' },
    }
  end,
  desc = 'mvn help:all-profiles',
}
