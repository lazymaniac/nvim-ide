return {
  name = 'Maven Build',
  builder = function()
    return {
      cmd = { 'mvn' },
      args = { 'clean', 'install' },
    }
  end,
  desc = 'mvn clean install',
  condition = {
    filetype = { 'java', 'xml' },
  },
}
