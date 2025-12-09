# Test standard library classes

def test_stdlib
  puts "\n=== Testing Standard Library ==="

  # Array
  arr = [3, 1, 4, 1, 5, 9, 2, 6]
  puts "Array: #{arr.inspect}"
  puts "  sorted: #{arr.sort.inspect}"
  puts "  uniq: #{arr.uniq.inspect}"
  puts "  map: #{arr.map { |x| x * 2 }.inspect}"
  puts "  select: #{arr.select { |x| x > 3 }.inspect}"
  puts "  reduce: #{arr.reduce(0) { |sum, x| sum + x }}"
  puts "  first(3): #{arr.first(3).inspect}"
  puts "  last(2): #{arr.last(2).inspect}"

  # Hash
  hash = { name: "Alice", age: 30, city: "NYC" }
  puts "\nHash: #{hash.inspect}"
  puts "  keys: #{hash.keys.inspect}"
  puts "  values: #{hash.values.inspect}"
  puts "  has_key?(:name): #{hash.has_key?(:name)}"
  hash[:country] = "USA"
  puts "  after merge: #{hash.inspect}"

  # String
  str = "  Hello, World!  "
  puts "\nString: '#{str}'"
  puts "  strip: '#{str.strip}'"
  puts "  upcase: '#{str.upcase}'"
  puts "  downcase: '#{str.downcase}'"
  puts "  split: #{str.strip.split(', ').inspect}"
  puts "  gsub: '#{str.gsub('World', 'Ruby')}'"
  puts "  include?: #{str.include?('Hello')}"
  puts "  length: #{str.length}"

  # Range
  range = (1..10)
  puts "\nRange: #{range.inspect}"
  puts "  to_a: #{range.to_a.inspect}"
  puts "  include?(5): #{range.include?(5)}"
  puts "  sum: #{range.sum}"

  # Numeric
  puts "\nNumeric:"
  puts "  -5.abs: #{-5.abs}"
  puts "  3.14.round: #{3.14.round}"
  puts "  3.14.floor: #{3.14.floor}"
  puts "  3.14.ceil: #{3.14.ceil}"
  puts "  10.times: #{(0...10).to_a.inspect}"

  # Time
  now = Time.now
  puts "\nTime: #{now}"
  puts "  year: #{now.year}"
  puts "  month: #{now.month}"
  puts "  day: #{now.day}"
  puts "  hour: #{now.hour}"
  puts "  min: #{now.min}"
  puts "  sec: #{now.sec}"

  # Math
  puts "\nMath:"
  puts "  sqrt(16): #{Math.sqrt(16)}"
  puts "  sin(0): #{Math.sin(0)}"
  puts "  cos(0): #{Math.cos(0)}"
  puts "  PI: #{Math::PI}"
  puts "  E: #{Math::E}"
  puts "  log(10): #{Math.log(10)}"

  # Random
  puts "\nRandom:"
  puts "  rand: #{rand}"
  puts "  rand(100): #{rand(100)}"
  puts "  [1,2,3].sample: #{[1, 2, 3].sample}"
  puts "  [1,2,3].shuffle: #{[1, 2, 3].shuffle.inspect}"

  puts "\nStdlib test: PASSED"
rescue => e
  puts "Stdlib test: FAILED - #{e.message}"
  puts e.backtrace.first(3).join("\n")
end
