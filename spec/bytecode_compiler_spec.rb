# frozen_string_literal: true

require "spec_helper"

RSpec.describe PortableMruby::BytecodeCompiler do
  subject(:compiler) { described_class.new }

  describe "#compile", :integration do
    it "compiles Ruby source to bytecode", if: cosmocc_available? do
      with_temp_ruby_file('puts "hello"') do |dir, rb_path|
        mrb_path = File.join(dir, "test.mrb")

        compiler.compile(rb_path, mrb_path)

        expect(File.exist?(mrb_path)).to be true
        expect(File.size(mrb_path)).to be > 0

        # mruby bytecode starts with "RITE" magic
        content = File.binread(mrb_path)
        expect(content[0..3]).to eq("RITE")
      end
    end

    it "raises CompileError for invalid Ruby syntax", if: cosmocc_available? do
      with_temp_ruby_file("def broken(") do |dir, rb_path|
        mrb_path = File.join(dir, "test.mrb")

        expect {
          compiler.compile(rb_path, mrb_path)
        }.to raise_error(PortableMruby::CompileError)
      end
    end

    it "raises CompileError for non-existent file", if: cosmocc_available? do
      Dir.mktmpdir do |dir|
        rb_path = File.join(dir, "nonexistent.rb")
        mrb_path = File.join(dir, "test.mrb")

        expect {
          compiler.compile(rb_path, mrb_path)
        }.to raise_error(PortableMruby::CompileError)
      end
    end
  end
end
