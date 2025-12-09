# frozen_string_literal: true

require_relative "lib/portable_mruby/version"

Gem::Specification.new do |spec|
  spec.name = "portable_mruby"
  spec.version = PortableMruby::VERSION
  spec.authors = ["Chris Hasinski"]
  spec.email = ["krzysztof.hasinski@gmail.com"]

  spec.summary = "Build truly portable Ruby executables using mruby and Cosmopolitan Libc"
  spec.description = <<~DESC
    portable_mruby compiles Ruby programs into single-file executables that run on
    Linux, macOS, Windows, FreeBSD, OpenBSD, and NetBSD without any dependencies.
    It uses mruby (embedded Ruby) and Cosmopolitan Libc to create "Actually Portable
    Executables" that work across x86_64 and ARM64 architectures.
  DESC
  spec.homepage = "https://github.com/khasinski/portable-mruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    # Include lib, exe, and vendor directories
    files = Dir["{lib,exe,vendor}/**/*", "LICENSE", "README.md"]
    files.reject { |f| File.directory?(f) }
  end

  spec.bindir = "exe"
  spec.executables = ["portable-mruby"]
  spec.require_paths = ["lib"]
end
