#!/usr/bin/env ruby

require 'yaml'

root = File.expand_path('../..', __dir__)
workflow_path = File.join(root, '.github/workflows/neovim.yml')
workflow = YAML.load_file(workflow_path)
full = workflow.fetch('jobs').fetch('full')
steps = full.fetch('steps')

uses = steps.each_with_object([]) do |step, result|
  result << step['uses'] if step['uses']
end
rendered_steps = steps.map(&:to_s).join("\n")

required_actions = {
  'Go >= 1.26' => 'actions/setup-go@v6',
  'Java/Javac >= 21' => 'actions/setup-java@v5',
  'Node >= 24.15' => 'actions/setup-node@v6',
  'Python 3.10-3.13' => 'actions/setup-python@v6',
  'Ruby >= 3' => 'ruby/setup-ruby@v1',
  'Rust' => 'dtolnay/rust-toolchain@stable',
  'GHC/Cabal' => 'haskell-actions/setup@v2',
  'Clojure' => 'DeLaGuardo/setup-clojure@13',
  'Scala/sbt' => 'coursier/setup-action@v3',
  'Dart/Flutter' => 'subosito/flutter-action@v2',
  'R' => 'r-lib/actions/setup-r@v2',
  'Terraform' => 'hashicorp/setup-terraform@v4',
  'Gradle' => 'gradle/actions/setup-gradle@v6',
}

errors = []
required_actions.each do |capability, action|
  errors << "#{capability} is not provisioned with #{action}" unless uses.include?(action)
end

required_fragments = {
  'Go floor' => "go-version\"=>\"1.26.0",
  'Java floor' => "java-version\"=>\"21",
  'Node floor' => "node-version\"=>\"24.15.0",
  'Python supported version' => "python-version\"=>\"3.13",
  'system/runtime installer' => 'tests/ci/install-full-system-runtimes.sh',
  'fail-fast runtime probes' => 'tests/ci/verify-full-runtimes.sh',
}

required_fragments.each do |capability, fragment|
  errors << "#{capability} is missing from the full job" unless rendered_steps.include?(fragment)
end


scripts = {
  'installer' => File.join(root, 'tests/ci/install-full-system-runtimes.sh'),
  'probe' => File.join(root, 'tests/ci/verify-full-runtimes.sh'),
}

scripts.each do |purpose, path|
  errors << "#{purpose} script is missing: #{path}" unless File.file?(path)
end

if File.file?(scripts['installer'])
  installer = File.read(scripts['installer'])
  {
    'Ansible' => 'ansible-core',
    'CMake' => 'cmake',
    'Ninja' => 'ninja',
    'container runtime' => 'podman',
    'Kotlin' => 'KOTLIN_VERSION=2.4.10',
    'Lua' => 'lua',
    'LuaRocks' => 'luarocks',
    'Maven' => 'maven',
    'PostgreSQL client' => 'postgresql',
    'Tree-sitter CLI' => 'tree-sitter-cli@0.26.3',
    'macOS arm64 Rosetta' => 'softwareupdate --install-rosetta',
  }.each do |capability, fragment|
    errors << "#{capability} is missing from the system installer" unless installer.include?(fragment)
  end
end

if File.file?(scripts['probe'])
  probe = File.read(scripts['probe'])
  %w[
    ansible ansible-playbook bash bundle cabal cc cmake curl dart flutter gem ghc ghcup git go gradle gzip
    java javac kotlinc lua luarocks mvn ninja node npm psql R rg ruby rustc cargo sbt scala tar
    terraform tree-sitter unzip
  ].each do |executable|
    errors << "#{executable} has no fail-fast probe" unless probe.match?(/\b#{Regexp.escape(executable)}\b/)
  end

  {
    'Go >= 1.26.0' => 'assert_version go 1.26.0',
    'Java >= 21.0.0' => 'assert_version java 21.0.0',
    'Javac >= 21.0.0' => 'assert_version javac 21.0.0',
    'Node >= 24.15.0' => 'assert_version node 24.15.0',
    'Python >= 3.10.0' => 'assert_version python3 3.10.0',
    'Python < 3.14.0' => 'assert_version_below python3 3.14.0',
    'Ruby >= 3.0.0' => 'assert_version ruby 3.0.0',
    'Rust >= 1.42.0' => 'assert_version rustc 1.42.0',
    'GHC >= 8.10.0' => 'assert_version ghc 8.10.0',
    'Cabal >= 3.0.0' => 'assert_version cabal 3.0.0',
    'LuaRocks >= 3.0.0' => 'assert_version luarocks 3.0.0',
    'Tree-sitter CLI >= 0.26.1' => 'assert_version tree-sitter 0.26.1',
    'Python venv capability' => 'python3 -m venv',
    'Ruby development headers' => "RbConfig::CONFIG.fetch('rubyhdrdir')",
    'macOS arm64 Rosetta capability' => "arch -x86_64 /usr/bin/true",
  }.each do |capability, fragment|
    errors << "#{capability} is not asserted" unless probe.include?(fragment)
  end
end

abort(errors.join("\n")) unless errors.empty?

puts 'full CI runtime provisioning contract is complete'
