# frozen_string_literal: true

require_relative "portable_mruby/version"

module PortableMruby
  class Error < StandardError; end
  class BuildError < Error; end
  class CompileError < Error; end
end

require_relative "portable_mruby/binary_manager"
require_relative "portable_mruby/bytecode_compiler"
require_relative "portable_mruby/c_generator"
require_relative "portable_mruby/builder"
require_relative "portable_mruby/cli"
