#!/usr/bin/env ruby

puts "Hello from portable mruby!"
puts "Arguments: #{ARGV.inspect}"
puts "Platform: #{RUBY_ENGINE} #{RUBY_VERSION}"
puts "Time: #{Time.now}"
