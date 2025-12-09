# frozen_string_literal: true

require "spec_helper"

RSpec.describe PortableMruby::CLI do
  describe "#run" do
    it "shows help when no command given" do
      cli = described_class.new([])

      expect {
        cli.run
      }.to output(/portable-mruby - Build portable Ruby executables/).to_stdout
    end

    it "shows help for help command" do
      cli = described_class.new(["help"])

      expect {
        cli.run
      }.to output(/Commands:/).to_stdout
    end

    it "shows version for version command" do
      cli = described_class.new(["version"])

      expect {
        cli.run
      }.to output(/portable-mruby \d+\.\d+\.\d+/).to_stdout
    end

    it "exits with error for unknown command" do
      cli = described_class.new(["unknown"])

      expect {
        cli.run
      }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
        .and output(/Unknown command: unknown/).to_stderr
    end
  end

  describe "build command" do
    it "requires --entry option" do
      cli = described_class.new(["build"])

      expect {
        cli.run
      }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
        .and output(/--entry is required/).to_stderr
    end

    it "shows help with -h flag" do
      cli = described_class.new(["build", "-h"])

      expect {
        cli.run
      }.to raise_error(SystemExit) { |e| expect(e.status).to eq(0) }
        .and output(/Usage: portable-mruby build/).to_stdout
    end

    it "parses all options correctly" do
      # Mock the builder to avoid actual build
      builder_double = instance_double(PortableMruby::Builder)
      allow(builder_double).to receive(:build)

      expect(PortableMruby::Builder).to receive(:new).with(
        entry_file: "main.rb",
        source_dir: "src/",
        output: "myapp.com",
        verbose: true,
        mruby_source: "/path/to/mruby"
      ).and_return(builder_double)

      cli = described_class.new([
        "build",
        "-e", "main.rb",
        "-d", "src/",
        "-o", "myapp.com",
        "-v",
        "--mruby-source", "/path/to/mruby"
      ])

      expect { cli.run }.to output(/Built:/).to_stdout
    end

    it "handles build errors gracefully" do
      allow(PortableMruby::Builder).to receive(:new).and_raise(
        PortableMruby::BuildError, "Something went wrong"
      )

      cli = described_class.new(["build", "-e", "main.rb"])

      expect {
        cli.run
      }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
        .and output(/Error: Something went wrong/).to_stderr
    end
  end

  describe ".run class method" do
    it "creates instance and runs" do
      expect_any_instance_of(described_class).to receive(:run)
      described_class.run(["help"])
    end
  end
end
