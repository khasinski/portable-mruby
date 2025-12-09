# Test classes, inheritance, modules

module Logging
  def log(msg)
    puts "[LOG] #{msg}"
  end
end

module Serializable
  def to_s
    instance_variables.map { |v| "#{v}=#{instance_variable_get(v)}" }.join(", ")
  end
end

class Animal
  include Logging

  attr_reader :name

  def initialize(name)
    @name = name
  end

  def speak
    raise NotImplementedError, "Subclass must implement"
  end
end

class Dog < Animal
  include Serializable

  attr_reader :breed

  def initialize(name, breed = "Unknown")
    super(name)
    @breed = breed
  end

  def speak
    "#{@name} says: Woof!"
  end
end

class Cat < Animal
  def speak
    "#{@name} says: Meow!"
  end
end

def test_classes
  puts "=== Testing Classes, Inheritance, Modules ==="

  dog = Dog.new("Buddy", "Golden Retriever")
  cat = Cat.new("Whiskers")

  puts dog.speak
  puts cat.speak

  dog.log("Dog created")
  puts "Dog to_s: #{dog}"

  # Test class methods
  puts "Dog class: #{dog.class}"
  puts "Dog is Animal? #{dog.is_a?(Animal)}"
  puts "Dog includes Logging? #{dog.class.include?(Logging)}"

  puts "Classes test: PASSED"
rescue => e
  puts "Classes test: FAILED - #{e.message}"
end
