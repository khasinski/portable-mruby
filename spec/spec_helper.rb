# frozen_string_literal: true

require "bundler/setup"

# Add lib to load path for development
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "portable_mruby"
require "fileutils"
require "tmpdir"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = "doc" if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed
end

# Helper to create temporary Ruby files for testing
def with_temp_ruby_file(content, filename: "test.rb")
  Dir.mktmpdir do |dir|
    path = File.join(dir, filename)
    File.write(path, content)
    yield dir, path
  end
end

# Helper to create a temporary project with multiple files
def with_temp_project(files)
  Dir.mktmpdir do |dir|
    files.each do |relative_path, content|
      full_path = File.join(dir, relative_path)
      FileUtils.mkdir_p(File.dirname(full_path))
      File.write(full_path, content)
    end
    yield dir
  end
end

# Check if cosmocc is available for integration tests
def cosmocc_available?
  cosmo_root = ENV["COSMO_ROOT"] || File.join(ENV["HOME"], ".portable-mruby", "cosmocc")
  File.exist?(File.join(cosmo_root, "bin", "cosmocc"))
end
