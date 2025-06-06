# frozen_string_literal: true

require "spec_helper"
require_relative "../lib/agtron"

RSpec.describe "Example" do
  describe "basic functionality" do
    it "should pass a simple test" do
      expect(true).to be true
    end

    it "should handle string operations" do
      result = "hello world"
      expect(result).to include("world")
      expect(result.length).to eq(11)
    end
  end

  describe "math operations" do
    it "should perform basic arithmetic" do
      expect(2 + 2).to eq(4)
      expect(10 - 5).to eq(5)
    end
  end

  describe "Agtron module" do
    it "should have a version" do
      expect(Agtron::VERSION).to eq("0.0.1")
    end
  end
end
