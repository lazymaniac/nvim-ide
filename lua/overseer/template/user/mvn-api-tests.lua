return {
  name = 'Maven Run Api Tests',
  builder = function()
    return {
      cmd = { 'mvn' },
      args = { 'verify', '-P api-tests' },
    }
  end,
  desc = 'mvn verify -P api-tests',
  condition = {
    filetype = { 'java', 'xml' },
  },
}
