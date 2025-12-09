# frozen_string_literal: true

require "spec_helper"

RSpec.describe PortableMruby do
  it "has a version number" do
    expect(PortableMruby::VERSION).not_to be_nil
    expect(PortableMruby::VERSION).to match(/\d+\.\d+\.\d+/)
  end

  it "has an mruby version number" do
    expect(PortableMruby::MRUBY_VERSION).not_to be_nil
  end

  describe "Error classes" do
    it "defines Error as base class" do
      expect(PortableMruby::Error).to be < StandardError
    end

    it "defines BuildError" do
      expect(PortableMruby::BuildError).to be < PortableMruby::Error
    end
  end
end
