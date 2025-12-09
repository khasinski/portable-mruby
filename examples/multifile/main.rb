# Main entry point

name = ARGV[0] || "World"
greeter = Greeter.new(name)
puts greeter.greet

calc = Calculator.new
puts "2 + 3 = #{calc.add(2, 3)}"
puts "4 * 5 = #{calc.multiply(4, 5)}"
