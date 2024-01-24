return {
  name = 'Maven Run Docker Tests',
  builder = function()
    return {
      cmd = { 'mvn' },
      args = { 'verify', '-P docker-tests' },
    }
  end,
  desc = 'mvn verify -P docker-tests',
  condition = {
    filetype = { 'java', 'xml' },
  },
}
