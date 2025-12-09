# Test exception handling

# Custom errors defined at top level
class CustomError < StandardError; end
class ValidationError < CustomError; end

def risky_operation(type)
  case type
  when :standard
    raise StandardError, "Standard error"
  when :custom
    raise CustomError, "Custom error"
  when :validation
    raise ValidationError, "Validation failed"
  when :runtime
    raise RuntimeError, "Runtime error"
  else
    "success"
  end
end

def with_ensure
  begin
    puts "In begin block"
    raise "Error in begin"
  rescue => e
    puts "In rescue: #{e.message}"
  ensure
    puts "In ensure (always runs)"
  end
end

def level3; raise "Deep error"; end
def level2; level3; end
def level1; level2; end

def test_exceptions
  puts "\n=== Testing Exceptions ==="

  # Basic rescue
  begin
    raise "Simple error"
  rescue => e
    puts "Caught: #{e.class} - #{e.message}"
  end

  # Multiple rescue clauses
  [:standard, :custom, :validation, :runtime, :none].each do |type|
    begin
      result = risky_operation(type)
      puts "#{type}: #{result}"
    rescue ValidationError => e
      puts "#{type}: ValidationError - #{e.message}"
    rescue CustomError => e
      puts "#{type}: CustomError - #{e.message}"
    rescue StandardError => e
      puts "#{type}: StandardError - #{e.message}"
    end
  end

  # Ensure block
  with_ensure

  # Retry
  attempts = 0
  begin
    attempts += 1
    puts "Attempt #{attempts}"
    raise "Retry error" if attempts < 3
    puts "Success on attempt #{attempts}"
  rescue
    retry if attempts < 3
    puts "Giving up after #{attempts} attempts"
  end

  # Raise with backtrace
  begin
    level1
  rescue => e
    puts "\nBacktrace test:"
    puts "  Error: #{e.message}"
    puts "  Backtrace depth: #{e.backtrace.size}"
  end

  puts "Exceptions test: PASSED"
rescue => e
  puts "Exceptions test: FAILED - #{e.message}"
end
