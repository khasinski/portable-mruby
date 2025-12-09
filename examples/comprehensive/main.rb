#!/usr/bin/env ruby
# Comprehensive mruby test suite

puts "=" * 60
puts "Portable mruby Comprehensive Test Suite"
puts "=" * 60
puts
puts "Ruby Engine: #{RUBY_ENGINE}"
puts "Ruby Version: #{RUBY_VERSION}"
puts "ARGV: #{ARGV.inspect}"
puts "Time: #{Time.now}"
puts

# Run all tests
test_classes
test_blocks
test_stdlib
test_fileio
test_exceptions
test_advanced

puts
puts "=" * 60
puts "All tests completed!"
puts "=" * 60
