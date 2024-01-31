return {
  name = 'Use Java 8 Runtime',
  builder = function()
    return {
      cmd = { 'sdk' },
      args = { 'use', 'java', '8.0.402-tem' },
    }
  end,
  desc = 'sdk use java 8.0.402-tem',
}
