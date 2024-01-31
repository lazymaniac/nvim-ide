return {
  name = 'Use Java 11 Runtime',
  builder = function()
    return {
      cmd = { 'sdk' },
      args = { 'use', 'java', '11.0.21-tem' },
    }
  end,
  desc = 'sdk use java 11.0.21-tem',
}
