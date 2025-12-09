# frozen_string_literal: true

require "optparse"

module PortableMruby
  class CLI
    def self.run(args = ARGV)
      new(args).run
    end

    def initialize(args)
      @args = args.dup
      @options = {
        entry: nil,
        dir: ".",
        output: "app.com",
        verbose: false,
        mruby_source: nil
      }
    end

    def run
      command = parse_command

      case command
      when "build"
        build
      when "version"
        version
      when "help", nil
        help
      else
        $stderr.puts "Unknown command: #{command}"
        $stderr.puts "Run 'portable-mruby help' for usage"
        exit 1
      end
    end

    private

    def parse_command
      # Extract command (first non-option argument)
      idx = @args.index { |arg| !arg.start_with?("-") }
      idx ? @args.delete_at(idx) : nil
    end

    def build
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: portable-mruby build [options]"
        opts.separator ""
        opts.separator "Options:"

        opts.on("-e", "--entry FILE", "Entry point Ruby file (required)") do |f|
          @options[:entry] = f
        end

        opts.on("-d", "--dir DIR", "Source directory (default: .)") do |d|
          @options[:dir] = d
        end

        opts.on("-o", "--output FILE", "Output binary name (default: app.com)") do |o|
          @options[:output] = o
        end

        opts.on("--mruby-source DIR", "Build mruby from source directory instead of using bundled") do |d|
          @options[:mruby_source] = d
        end

        opts.on("-v", "--verbose", "Verbose output") do
          @options[:verbose] = true
        end

        opts.on("-h", "--help", "Show this help") do
          puts opts
          exit
        end
      end

      parser.parse!(@args)

      unless @options[:entry]
        $stderr.puts "Error: --entry is required"
        $stderr.puts parser
        exit 1
      end

      builder = Builder.new(
        entry_file: @options[:entry],
        source_dir: @options[:dir],
        output: @options[:output],
        verbose: @options[:verbose],
        mruby_source: @options[:mruby_source]
      )

      builder.build
      puts "Built: #{@options[:output]}"
    rescue Error => e
      $stderr.puts "Error: #{e.message}"
      exit 1
    end

    def version
      puts "portable-mruby #{VERSION}"
      puts "mruby #{MRUBY_VERSION}"
    end

    def help
      puts <<~HELP
        portable-mruby - Build portable Ruby executables

        Usage:
          portable-mruby <command> [options]

        Commands:
          build     Build a portable executable from Ruby source
          version   Show version information
          help      Show this help message

        Build Options:
          -e, --entry FILE        Entry point Ruby file (required)
          -d, --dir DIR           Source directory (default: .)
          -o, --output FILE       Output binary name (default: app.com)
          --mruby-source DIR      Build mruby from source directory
          -v, --verbose           Verbose output

        Environment Variables:
          COSMO_ROOT              Path to cosmocc toolchain (auto-downloaded if not set)

        Examples:
          portable-mruby build --entry main.rb --dir src/ --output myapp.com
          portable-mruby build -e app.rb -o app.com
          portable-mruby build -e main.rb --mruby-source ~/mruby

        The resulting binary runs on Linux, macOS, Windows, FreeBSD, OpenBSD, and NetBSD
        for both x86_64 and ARM64 architectures.
      HELP
    end
  end
end
