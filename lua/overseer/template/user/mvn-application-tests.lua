return {
  name = 'Maven Run Application Tests',
  builder = function()
    return {
      cmd = { 'mvn' },
      args = { 'verify', '-P application-tests' },
    }
  end,
  desc = 'mvn verify -P application-tests',
}
