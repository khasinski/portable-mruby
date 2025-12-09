# frozen_string_literal: true

require "tempfile"
require "fileutils"

module PortableMruby
  class BytecodeCompiler
    def initialize(mrbc_path: nil)
      @mrbc_path = mrbc_path || BinaryManager.mrbc_path
    end

    # Compile a single Ruby file to bytecode
    def compile(input_rb, output_mrb = nil)
      output_mrb ||= input_rb.sub(/\.rb$/, ".mrb")

      unless system(@mrbc_path, "-o", output_mrb, input_rb)
        raise CompileError, "Failed to compile #{input_rb}"
      end

      output_mrb
    end

    # Compile Ruby source to bytecode and return as C array
    def compile_to_c_array(input_rb, symbol_name)
      Tempfile.create(["bytecode", ".mrb"]) do |mrb_file|
        compile(input_rb, mrb_file.path)
        bytes = File.binread(mrb_file.path).bytes
        format_c_array(bytes, symbol_name)
      end
    end

    # Compile Ruby source string to bytecode
    def compile_string(ruby_source, symbol_name)
      Tempfile.create(["source", ".rb"]) do |rb_file|
        rb_file.write(ruby_source)
        rb_file.close
        compile_to_c_array(rb_file.path, symbol_name)
      end
    end

    private

    def format_c_array(bytes, symbol_name)
      byte_lines = bytes.each_slice(16).map do |slice|
        "    " + slice.map { |b| format("0x%02x", b) }.join(", ")
      end

      <<~C
        static const uint8_t #{symbol_name}[] = {
        #{byte_lines.join(",\n")}
        };
        static const size_t #{symbol_name}_len = #{bytes.size};
      C
    end
  end
end
