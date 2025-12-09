# Test blocks, procs, lambdas

def test_blocks
  puts "\n=== Testing Blocks, Procs, Lambdas ==="

  # Basic block
  result = []
  [1, 2, 3].each { |x| result << x * 2 }
  puts "each with block: #{result.inspect}"

  # Block with yield
  def with_timing
    start = Time.now
    result = yield
    elapsed = Time.now - start
    puts "Elapsed: #{elapsed}s"
    result
  end

  with_timing { 1 + 1; "done" }  # Note: sleep() not available in base mruby

  # Proc
  doubler = Proc.new { |x| x * 2 }
  puts "Proc call: #{doubler.call(5)}"

  # Lambda
  tripler = ->(x) { x * 3 }
  puts "Lambda call: #{tripler.call(5)}"

  # Proc vs Lambda return behavior
  def test_proc_return
    p = Proc.new { return "from proc" }
    p.call
    "after proc"
  end

  def test_lambda_return
    l = -> { return "from lambda" }
    l.call
    "after lambda"
  end

  puts "Proc return: #{test_proc_return}"
  puts "Lambda return: #{test_lambda_return}"

  # Closure
  def make_counter
    count = 0
    -> { count += 1 }
  end

  counter = make_counter
  puts "Counter: #{counter.call}, #{counter.call}, #{counter.call}"

  puts "Blocks test: PASSED"
rescue => e
  puts "Blocks test: FAILED - #{e.message}"
  puts e.backtrace.first(3).join("\n")
end
