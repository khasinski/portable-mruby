# frozen_string_literal: true

require "fileutils"
require "open-uri"

module PortableMruby
  class BinaryManager
    COSMOCC_URL = "https://cosmo.zip/pub/cosmocc/cosmocc.zip"

    class << self
      # Check if all required binaries are available
      def ensure_available(mruby_source: nil)
        ensure_cosmocc
        if mruby_source
          build_mruby_from_source(mruby_source)
        else
          ensure_bundled_mruby
        end
      end

      # Path to mrbc compiler
      def mrbc_path
        @mrbc_path || bundled_mrbc_path
      end

      # Path to cosmocc compiler
      def cosmocc_path
        File.join(cosmocc_dir, "bin", "cosmocc")
      end

      # Path to cosmoc++ compiler
      def cosmocxx_path
        File.join(cosmocc_dir, "bin", "cosmoc++")
      end

      # Path to cosmoar archiver
      def cosmoar_path
        File.join(cosmocc_dir, "bin", "cosmoar")
      end

      # Path to libmruby.a
      def libmruby_path
        @libmruby_path || bundled_libmruby_path
      end

      # Path to mruby include directory
      def include_path
        @include_path || bundled_include_path
      end

      # Path to mruby lib directory
      def lib_path
        @lib_path || bundled_lib_path
      end

      # Directory for cosmocc toolchain
      def cosmocc_dir
        ENV["COSMO_ROOT"] || default_cosmocc_dir
      end

      # Reset paths (used after building from source)
      def reset_paths!
        @mrbc_path = nil
        @libmruby_path = nil
        @include_path = nil
        @lib_path = nil
      end

      private

      # Bundled paths (shipped with gem)
      def bundled_dir
        # __dir__ is lib/portable_mruby, so go up 2 levels to gem root
        File.expand_path("../../vendor/mruby", __dir__)
      end

      def bundled_mrbc_path
        File.join(bundled_dir, "bin", "mrbc.com")
      end

      def bundled_libmruby_path
        File.join(bundled_dir, "lib", "libmruby.a")
      end

      def bundled_include_path
        File.join(bundled_dir, "include")
      end

      def bundled_lib_path
        File.join(bundled_dir, "lib")
      end

      # Default cosmocc location
      def default_cosmocc_dir
        File.join(ENV.fetch("HOME"), ".portable-mruby", "cosmocc")
      end

      # Cache directory for custom mruby builds
      def cache_dir
        File.join(ENV.fetch("HOME"), ".portable-mruby", "cache")
      end

      # Ensure bundled mruby files exist
      def ensure_bundled_mruby
        unless File.exist?(bundled_mrbc_path)
          raise BuildError, "Bundled mrbc not found at #{bundled_mrbc_path}. Gem may be corrupted."
        end

        unless File.exist?(bundled_libmruby_path)
          raise BuildError, "Bundled libmruby.a not found at #{bundled_libmruby_path}. Gem may be corrupted."
        end

        unless File.exist?(File.join(bundled_include_path, "mruby.h"))
          raise BuildError, "Bundled mruby headers not found. Gem may be corrupted."
        end
      end

      # Ensure cosmocc is available
      def ensure_cosmocc
        return if File.exist?(cosmocc_path)

        if ENV["COSMO_ROOT"]
          raise BuildError, "COSMO_ROOT is set but cosmocc not found at #{cosmocc_path}"
        end

        puts "Cosmopolitan toolchain not found."
        puts "Downloading cosmocc (~60MB)..."

        download_cosmocc
      end

      # Download and extract cosmocc
      def download_cosmocc
        FileUtils.mkdir_p(default_cosmocc_dir)

        zip_path = File.join(default_cosmocc_dir, "cosmocc.zip")

        # Download with progress
        download_with_progress(COSMOCC_URL, zip_path)

        puts "Extracting cosmocc..."
        Dir.chdir(default_cosmocc_dir) do
          system("unzip", "-q", "cosmocc.zip") or raise BuildError, "Failed to extract cosmocc"
        end

        FileUtils.rm(zip_path)
        puts "cosmocc installed to #{default_cosmocc_dir}"
      end

      # Build mruby from custom source
      def build_mruby_from_source(source_path)
        source_path = File.expand_path(source_path)

        unless File.directory?(source_path)
          raise BuildError, "mruby source directory not found: #{source_path}"
        end

        unless File.exist?(File.join(source_path, "Rakefile"))
          raise BuildError, "Invalid mruby source directory (no Rakefile): #{source_path}"
        end

        puts "Building mruby from source: #{source_path}"

        # Write our build config
        build_config_path = File.join(source_path, "build_config", "portable_mruby.rb")
        File.write(build_config_path, generate_build_config)

        # Build mruby
        Dir.chdir(source_path) do
          env = { "COSMO_ROOT" => cosmocc_dir }

          # Clean and build
          unless system(env, "rake", "deep_clean", exception: false)
            system(env, "rake", "clean")
          end

          system(env, "rake", "MRUBY_CONFIG=portable_mruby") or
            raise BuildError, "Failed to build mruby"
        end

        # Set paths to built artifacts
        build_dir = File.join(source_path, "build", "host")
        @mrbc_path = File.join(build_dir, "bin", "mrbc.com")
        @libmruby_path = File.join(build_dir, "lib", "libmruby.a")
        @lib_path = File.join(build_dir, "lib")

        # Include path needs both source and build includes
        @include_path = build_dir

        # Create a combined include directory
        combined_include = File.join(cache_dir, "include")
        FileUtils.rm_rf(combined_include)
        FileUtils.mkdir_p(combined_include)
        FileUtils.cp_r(File.join(source_path, "include", "."), combined_include)
        FileUtils.cp_r(File.join(build_dir, "include", "."), combined_include)
        @include_path = combined_include

        puts "mruby built successfully from #{source_path}"
      end

      # Generate build config for custom mruby builds
      def generate_build_config
        <<~RUBY
          # Build configuration for portable-mruby
          # Auto-generated - do not edit

          COSMO_ROOT = ENV['COSMO_ROOT']

          unless COSMO_ROOT && File.directory?(COSMO_ROOT)
            raise "COSMO_ROOT environment variable must point to cosmocc directory"
          end

          MRuby::Build.new do |conf|
            # C compiler
            conf.cc do |cc|
              cc.command = "\#{COSMO_ROOT}/bin/cosmocc"
              cc.flags = %w[-Os -fno-omit-frame-pointer]
            end

            # C++ compiler
            conf.cxx do |cxx|
              cxx.command = "\#{COSMO_ROOT}/bin/cosmoc++"
              cxx.flags = conf.cc.flags.dup
            end

            # Linker
            conf.linker do |linker|
              linker.command = "\#{COSMO_ROOT}/bin/cosmocc"
              linker.flags = %w[-static]
            end

            # Archiver
            conf.archiver do |archiver|
              archiver.command = "\#{COSMO_ROOT}/bin/cosmoar"
            end

            # APE binaries use .com extension
            conf.exts.executable = '.com'

            # Explicitly select POSIX HALs
            conf.gem core: 'hal-posix-io'
            conf.gem core: 'hal-posix-socket'
            conf.gem core: 'hal-posix-dir'

            # Standard library
            conf.gembox 'stdlib'
            conf.gembox 'stdlib-ext'
            conf.gembox 'stdlib-io'
            conf.gembox 'math'
            conf.gembox 'metaprog'

            # Bytecode compiler only (we just need mrbc and libmruby.a)
            conf.gem core: 'mruby-bin-mrbc'
          end
        RUBY
      end

      # Download file with progress indicator
      def download_with_progress(url, dest)
        URI.open(url, # rubocop:disable Security/Open
                 content_length_proc: lambda { |total|
                   @total_size = total
                   @downloaded = 0
                 },
                 progress_proc: lambda { |size|
                   @downloaded = size
                   if @total_size
                     percent = (@downloaded.to_f / @total_size * 100).round(1)
                     print "\rDownloading: #{percent}% (#{@downloaded / 1024 / 1024}MB / #{@total_size / 1024 / 1024}MB)"
                   end
                 }) do |remote|
          File.open(dest, "wb") { |f| f.write(remote.read) }
        end
        puts # newline after progress
      end
    end
  end
end
