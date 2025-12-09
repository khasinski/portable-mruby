# frozen_string_literal: true

require "spec_helper"

RSpec.describe PortableMruby::BinaryManager do
  describe ".bundled paths" do
    it "returns correct mrbc path" do
      path = described_class.mrbc_path
      expect(path).to end_with("vendor/mruby/bin/mrbc.com")
    end

    it "returns correct libmruby path" do
      path = described_class.libmruby_path
      expect(path).to end_with("vendor/mruby/lib/libmruby.a")
    end

    it "returns correct include path" do
      path = described_class.include_path
      expect(path).to end_with("vendor/mruby/include")
    end

    it "returns correct lib path" do
      path = described_class.lib_path
      expect(path).to end_with("vendor/mruby/lib")
    end
  end

  describe ".cosmocc_dir" do
    context "when COSMO_ROOT is set" do
      around do |example|
        original = ENV["COSMO_ROOT"]
        ENV["COSMO_ROOT"] = "/custom/cosmo"
        example.run
        ENV["COSMO_ROOT"] = original
      end

      it "returns COSMO_ROOT value" do
        expect(described_class.cosmocc_dir).to eq("/custom/cosmo")
      end
    end

    context "when COSMO_ROOT is not set" do
      around do |example|
        original = ENV["COSMO_ROOT"]
        ENV.delete("COSMO_ROOT")
        example.run
        ENV["COSMO_ROOT"] = original
      end

      it "returns default path in home directory" do
        expect(described_class.cosmocc_dir).to eq(
          File.join(ENV["HOME"], ".portable-mruby", "cosmocc")
        )
      end
    end
  end

  describe ".cosmocc_path" do
    it "returns path to cosmocc binary" do
      expect(described_class.cosmocc_path).to end_with("bin/cosmocc")
    end
  end

  describe ".cosmocxx_path" do
    it "returns path to cosmoc++ binary" do
      expect(described_class.cosmocxx_path).to end_with("bin/cosmoc++")
    end
  end

  describe ".cosmoar_path" do
    it "returns path to cosmoar binary" do
      expect(described_class.cosmoar_path).to end_with("bin/cosmoar")
    end
  end

  describe ".reset_paths!" do
    it "resets custom paths to nil" do
      # This is mainly for testing after --mruby-source builds
      described_class.reset_paths!
      # Should not raise and paths should return bundled defaults
      expect(described_class.mrbc_path).to end_with("vendor/mruby/bin/mrbc.com")
    end
  end

  describe "bundled files existence" do
    it "has bundled mrbc.com" do
      expect(File.exist?(described_class.mrbc_path)).to be true
    end

    it "has bundled libmruby.a" do
      expect(File.exist?(described_class.libmruby_path)).to be true
    end

    it "has bundled mruby.h" do
      header_path = File.join(described_class.include_path, "mruby.h")
      expect(File.exist?(header_path)).to be true
    end

    it "has bundled aarch64 libmruby.a" do
      aarch64_path = File.join(described_class.lib_path, ".aarch64", "libmruby.a")
      expect(File.exist?(aarch64_path)).to be true
    end
  end
end
