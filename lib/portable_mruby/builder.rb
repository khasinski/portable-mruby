# frozen_string_literal: true

require "tempfile"
require "fileutils"

module PortableMruby
  class Builder
    attr_reader :entry_file, :source_dir, :output, :verbose, :mruby_source

    def initialize(entry_file:, source_dir: ".", output: "app.com", verbose: false, mruby_source: nil)
      @entry_file = entry_file
      @source_dir = File.expand_path(source_dir)
      @output = output
      @verbose = verbose
      @mruby_source = mruby_source
      @temp_dir = nil
    end

    def build
      BinaryManager.ensure_available(mruby_source: @mruby_source)

      @temp_dir = Dir.mktmpdir("portable-mruby")

      ruby_files = collect_ruby_files
      log "Found #{ruby_files.size} Ruby file(s)"

      bytecode_files = compile_to_bytecode(ruby_files)
      log "Compiled #{bytecode_files.size} bytecode file(s)"

      c_source = generate_c_source(bytecode_files)
      c_file = File.join(@temp_dir, "app.c")
      File.write(c_file, c_source)
      log "Generated C source (#{c_source.size} bytes)"

      compile_binary(c_file)
      log "Built: #{@output}"

      @output
    ensure
      FileUtils.rm_rf(@temp_dir) if @temp_dir
      BinaryManager.reset_paths!
    end

    private

    def log(message)
      puts message if @verbose
    end

    def collect_ruby_files
      # Find all Ruby files in source directory
      pattern = File.join(@source_dir, "**", "*.rb")
      files = Dir.glob(pattern).sort

      # Ensure entry file exists
      entry_path = if File.absolute_path?(@entry_file)
                     @entry_file
                   else
                     File.join(@source_dir, @entry_file)
                   end

      unless File.exist?(entry_path)
        raise BuildError, "Entry file not found: #{entry_path}"
      end

      # Remove entry file from list and add it last (executed last)
      files.delete(entry_path)
      files << entry_path

      files
    end

    def compile_to_bytecode(ruby_files)
      compiler = BytecodeCompiler.new

      ruby_files.map do |rb_file|
        # Create a unique name for the bytecode file
        relative_path = rb_file.sub("#{@source_dir}/", "")
        mrb_name = relative_path.gsub("/", "_").sub(/\.rb$/, ".mrb")
        mrb_path = File.join(@temp_dir, mrb_name)

        compiler.compile(rb_file, mrb_path)

        {
          rb_path: rb_file,
          mrb_path: mrb_path,
          name: relative_path
        }
      end
    end

    def generate_c_source(bytecode_files)
      CGenerator.new(bytecode_files).generate
    end

    def compile_binary(c_file)
      cc = BinaryManager.cosmocc_path
      include_path = BinaryManager.include_path
      lib_path = BinaryManager.lib_path

      cmd = [
        cc,
        "-Os",
        "-static",
        "-o", @output,
        c_file,
        "-I#{include_path}",
        "-L#{lib_path}",
        "-lmruby",
        "-lm"
      ]

      log "Running: #{cmd.join(' ')}" if @verbose

      unless system(*cmd)
        raise BuildError, "Failed to compile binary"
      end
    end
  end
end
