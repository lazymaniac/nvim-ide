return {
  name = 'Maven Run Component Tests',
  builder = function()
    return {
      cmd = { 'mvn' },
      args = { 'verify', '-P component-tests' },
    }
  end,
  desc = 'mvn verify -P component-tests',
}
