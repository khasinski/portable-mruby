# frozen_string_literal: true

module PortableMruby
  class BytecodeCompiler
    def initialize(mrbc_path: nil)
      @mrbc_path = mrbc_path || BinaryManager.mrbc_path
    end

    def compile(input_rb, output_mrb = nil)
      output_mrb ||= input_rb.sub(/\.rb$/, ".mrb")

      unless system(@mrbc_path, "-o", output_mrb, input_rb)
        raise CompileError, "Failed to compile #{input_rb}"
      end

      output_mrb
    end
  end
end
