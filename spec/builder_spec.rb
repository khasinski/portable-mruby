# frozen_string_literal: true

require "spec_helper"

RSpec.describe PortableMruby::Builder do
  describe "#initialize" do
    it "has default entry_file of nil" do
      builder = described_class.new
      expect(builder.entry_file).to be_nil
    end

    it "has default source_dir of current directory" do
      builder = described_class.new
      expect(builder.source_dir).to eq(File.expand_path("."))
    end

    it "has default output of app.com" do
      builder = described_class.new
      expect(builder.output).to eq("app.com")
    end

    it "has default verbose of false" do
      builder = described_class.new
      expect(builder.verbose).to be false
    end

    it "has default mruby_source of nil" do
      builder = described_class.new
      expect(builder.mruby_source).to be_nil
    end

    it "accepts all optional parameters" do
      builder = described_class.new(
        entry_file: "app.rb",
        source_dir: "/tmp/src",
        output: "myapp.com",
        verbose: true,
        mruby_source: "/path/to/mruby"
      )

      expect(builder.entry_file).to eq("app.rb")
      expect(builder.source_dir).to eq("/tmp/src")
      expect(builder.output).to eq("myapp.com")
      expect(builder.verbose).to be true
      expect(builder.mruby_source).to eq("/path/to/mruby")
    end
  end

  describe "#build", :integration do
    it "raises BuildError when entry file not found" do
      with_temp_project({ "other.rb" => "# other" }) do |dir|
        builder = described_class.new(
          entry_file: "nonexistent.rb",
          source_dir: dir
        )

        expect {
          builder.build
        }.to raise_error(PortableMruby::BuildError, /Entry file not found/)
      end
    end

    it "raises BuildError when no Ruby files found" do
      with_temp_project({}) do |dir|
        builder = described_class.new(source_dir: dir)

        expect {
          builder.build
        }.to raise_error(PortableMruby::BuildError, /No Ruby files found/)
      end
    end

    it "builds without entry file (sorted order)", if: cosmocc_available? do
      files = {
        "a_first.rb" => "$order ||= []; $order << 'a'",
        "b_second.rb" => "$order << 'b'",
        "c_third.rb" => "$order << 'c'; puts $order.join(',')"
      }

      with_temp_project(files) do |dir|
        output = File.join(dir, "test.com")
        builder = described_class.new(source_dir: dir, output: output)

        builder.build

        result = `#{output} 2>&1`
        expect(result.strip).to eq("a,b,c")
      end
    end

    it "builds with entry file running last", if: cosmocc_available? do
      files = {
        "lib/helper.rb" => "module Helper; end",
        "lib/utils.rb" => "module Utils; end",
        "main.rb" => "puts 'hello'"
      }

      with_temp_project(files) do |dir|
        output = File.join(dir, "test.com")
        builder = described_class.new(
          entry_file: "main.rb",
          source_dir: dir,
          output: output
        )

        builder.build

        expect(File.exist?(output)).to be true
        expect(File.size(output)).to be > 1_000_000
      end
    end

    it "creates working executable", if: cosmocc_available? do
      with_temp_ruby_file('puts "test output"', filename: "main.rb") do |dir, _|
        output = File.join(dir, "test.com")
        builder = described_class.new(source_dir: dir, output: output)

        builder.build

        result = `#{output} 2>&1`
        expect(result.strip).to eq("test output")
        expect($?.exitstatus).to eq(0)
      end
    end

    it "passes ARGV to the executable", if: cosmocc_available? do
      with_temp_ruby_file('puts ARGV.join(",")') do |dir, _|
        output = File.join(dir, "test.com")
        builder = described_class.new(source_dir: dir, output: output)

        builder.build

        result = `#{output} arg1 arg2 arg3 2>&1`
        expect(result.strip).to eq("arg1,arg2,arg3")
      end
    end

    it "cleans up temporary files after build", if: cosmocc_available? do
      temp_dirs_before = Dir.glob(File.join(Dir.tmpdir, "portable-mruby*"))

      with_temp_ruby_file('puts "hello"') do |dir, _|
        output = File.join(dir, "test.com")
        builder = described_class.new(source_dir: dir, output: output)

        builder.build
      end

      temp_dirs_after = Dir.glob(File.join(Dir.tmpdir, "portable-mruby*"))
      expect(temp_dirs_after).to eq(temp_dirs_before)
    end
  end
end
