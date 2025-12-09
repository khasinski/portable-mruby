# Test advanced Ruby features

# Struct - defined at top level
Person = Struct.new(:name, :age, :city)

# Dynamic accessor class - defined at top level
class DynamicAccessor
  def initialize(data)
    @data = data
  end

  def method_missing(name, *args)
    if name.to_s.end_with?("=")
      @data[name.to_s.chop.to_sym] = args.first
    else
      @data[name]
    end
  end
end

# Calculator with define_method - defined at top level
class DynamicCalculator
  [:add, :subtract, :multiply].each do |op|
    define_method("#{op}_ten") do |x|
      case op
      when :add then x + 10
      when :subtract then x - 10
      when :multiply then x * 10
      end
    end
  end
end

def test_advanced
  puts "\n=== Testing Advanced Features ==="

  # Struct
  alice = Person.new("Alice", 30, "NYC")
  puts "Struct: #{alice.inspect}"
  puts "  name: #{alice.name}, age: #{alice.age}"

  # method_missing
  obj = DynamicAccessor.new({ foo: 1, bar: 2 })
  puts "\nmethod_missing:"
  puts "  obj.foo: #{obj.foo}"
  obj.baz = 3
  puts "  obj.baz = 3: #{obj.baz}"

  # Singleton methods
  str = "hello"
  def str.shout
    upcase + "!"
  end
  puts "\nSingleton method: #{str.shout}"

  # define_method
  calc = DynamicCalculator.new
  puts "\ndefine_method:"
  puts "  add_ten(5): #{calc.add_ten(5)}"
  puts "  subtract_ten(15): #{calc.subtract_ten(15)}"
  puts "  multiply_ten(3): #{calc.multiply_ten(3)}"

  # Enumerator
  fib = Enumerator.new do |y|
    a, b = 0, 1
    loop do
      y << a
      a, b = b, a + b
    end
  end
  puts "\nEnumerator (Fibonacci): #{fib.take(10).inspect}"

  # Fiber
  begin
    fiber = Fiber.new do
      Fiber.yield 1
      Fiber.yield 2
      3
    end
    puts "\nFiber: #{fiber.resume}, #{fiber.resume}, #{fiber.resume}"
  rescue NameError
    puts "\nFiber: not available"
  end

  # Object introspection
  puts "\nIntrospection:"
  puts "  Dog.ancestors: #{Dog.ancestors.inspect}"
  puts "  Dog.instance_methods(false): #{Dog.instance_methods(false).inspect}"
  puts "  alice.instance_variables: #{alice.instance_variables.inspect}"

  # Binding
  begin
    x = 10
    b = binding
    puts "\nBinding:"
    puts "  eval('x * 2', b): #{eval('x * 2', b)}"
  rescue NameError
    puts "\nBinding: not available"
  end

  puts "Advanced test: PASSED"
rescue => e
  puts "Advanced test: FAILED - #{e.message}"
  puts e.backtrace.first(5).join("\n")
end
