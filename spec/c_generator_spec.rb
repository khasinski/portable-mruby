# frozen_string_literal: true

require "spec_helper"

RSpec.describe PortableMruby::CGenerator do
  describe "#generate" do
    it "generates C source with embedded bytecode" do
      # Create fake bytecode files
      Dir.mktmpdir do |dir|
        mrb1 = File.join(dir, "file1.mrb")
        mrb2 = File.join(dir, "file2.mrb")

        File.binwrite(mrb1, "RITE\x00\x01\x02\x03")
        File.binwrite(mrb2, "RITE\x04\x05\x06\x07")

        bytecode_files = [
          { mrb_path: mrb1, name: "lib/helper.rb" },
          { mrb_path: mrb2, name: "main.rb" }
        ]

        generator = described_class.new(bytecode_files)
        c_source = generator.generate

        # Check includes
        expect(c_source).to include('#include <mruby.h>')
        expect(c_source).to include('#include <mruby/compile.h>')

        # Check bytecode arrays
        expect(c_source).to include("static const uint8_t bytecode_0[]")
        expect(c_source).to include("static const uint8_t bytecode_1[]")

        # Check byte values from fake bytecode
        expect(c_source).to include("0x52, 0x49, 0x54, 0x45") # "RITE"

        # Check main function
        expect(c_source).to include("int main(int argc, char **argv)")
        expect(c_source).to include("mrb_open()")
        expect(c_source).to include("mrb_load_irep(")
        expect(c_source).to include("mrb_close(mrb)")

        # Check ARGV setup
        expect(c_source).to include("ARGV")
      end
    end

    it "handles empty bytecode list" do
      generator = described_class.new([])
      c_source = generator.generate

      expect(c_source).to include("int main(")
      expect(c_source).to include("mrb_open()")
    end

    it "escapes special characters in file names" do
      Dir.mktmpdir do |dir|
        mrb = File.join(dir, "test.mrb")
        File.binwrite(mrb, "RITE\x00")

        bytecode_files = [
          { mrb_path: mrb, name: 'file"with"quotes.rb' }
        ]

        generator = described_class.new(bytecode_files)
        c_source = generator.generate

        # Should still generate valid C
        expect(c_source).to include("bytecode_0")
      end
    end

    describe "__main__ support" do
      it "includes code to call __main__ if defined" do
        generator = described_class.new([])
        c_source = generator.generate

        expect(c_source).to include('mrb_respond_to(mrb, mrb_top_self(mrb), mrb_intern_lit(mrb, "__main__"))')
      end

      it "supports __main__(argv) signature with full argv array" do
        generator = described_class.new([])
        c_source = generator.generate

        # Should build full_argv including program name (argv[0])
        expect(c_source).to include("mrb_value full_argv = mrb_ary_new_capa(mrb, argc)")
        expect(c_source).to include("for (i = 0; i < argc; i++)")
        expect(c_source).to include('mrb_funcall(mrb, mrb_top_self(mrb), "__main__", 1, full_argv)')
      end

      it "falls back to __main__() if ArgumentError is raised" do
        generator = described_class.new([])
        c_source = generator.generate

        # Should catch ArgumentError and retry without args
        expect(c_source).to include("ArgumentError")
        expect(c_source).to include('mrb_funcall(mrb, mrb_top_self(mrb), "__main__", 0)')
      end

      it "only calls __main__ if no prior exception occurred" do
        generator = described_class.new([])
        c_source = generator.generate

        # Should check !mrb->exc before calling __main__
        expect(c_source).to include("if (!mrb->exc && mrb_respond_to")
      end
    end
  end
end
