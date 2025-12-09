# Test File I/O operations

def test_fileio
  puts "\n=== Testing File I/O ==="

  test_file = "/tmp/mruby_test_#{$$}.txt"
  test_dir = "/tmp/mruby_test_dir_#{$$}"

  # Write file
  File.open(test_file, "w") do |f|
    f.puts "Line 1"
    f.puts "Line 2"
    f.write "Line 3 (no newline)"
  end
  puts "Written to: #{test_file}"

  # Read file
  content = File.open(test_file, "r") { |f| f.read }
  puts "Read content:\n#{content}"

  # File info
  puts "\nFile info:"
  puts "  exist?: #{File.exist?(test_file)}"
  puts "  size: #{File.size(test_file)}"
  puts "  file?: #{File.file?(test_file)}"
  puts "  directory?: #{File.directory?(test_file)}"
  # Note: readable?/writable? not available in mruby's default File class

  # File path operations
  puts "\nPath operations:"
  puts "  basename: #{File.basename(test_file)}"
  puts "  dirname: #{File.dirname(test_file)}"
  puts "  extname: #{File.extname(test_file)}"
  puts "  expand_path('.'): #{File.expand_path('.')}"

  # Directory operations
  Dir.mkdir(test_dir)
  puts "\nDirectory created: #{test_dir}"
  puts "  directory?: #{File.directory?(test_dir)}"

  # List directory
  puts "\nDir.entries('/tmp') sample: #{Dir.entries('/tmp').first(5).inspect}"
  puts "Dir.pwd: #{Dir.pwd}"

  # Cleanup
  File.delete(test_file)
  Dir.rmdir(test_dir)
  puts "\nCleanup: deleted test file and directory"

  puts "File I/O test: PASSED"
rescue => e
  puts "File I/O test: FAILED - #{e.message}"
  puts e.backtrace.first(3).join("\n")
  # Cleanup on failure
  File.delete(test_file) if File.exist?(test_file) rescue nil
  Dir.rmdir(test_dir) if File.directory?(test_dir) rescue nil
end
