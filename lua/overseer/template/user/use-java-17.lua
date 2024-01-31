return {
  name = 'Use Java 17 Runtime',
  builder = function()
    return {
      cmd = { 'sdk' },
      args = { 'use', 'java', '17.0.9-tem' },
    }
  end,
  desc = 'sdk use java 17.0.9-tem',
}
