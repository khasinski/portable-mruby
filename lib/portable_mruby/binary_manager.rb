# frozen_string_literal: true

require "fileutils"
require "open-uri"

module PortableMruby
  class BinaryManager
    COSMOCC_URL = "https://cosmo.zip/pub/cosmocc/cosmocc.zip"

    class << self
      def ensure_available(mruby_source: nil)
        ensure_cosmocc
        if mruby_source
          build_mruby_from_source(mruby_source)
        else
          ensure_bundled_mruby
        end
      end

      def mrbc_path
        @mrbc_path || bundled_mrbc_path
      end

      def cosmocc_path
        File.join(cosmocc_dir, "bin", "cosmocc")
      end

      def libmruby_path
        @libmruby_path || bundled_libmruby_path
      end

      def include_path
        @include_path || bundled_include_path
      end

      def lib_path
        @lib_path || bundled_lib_path
      end

      def cosmocc_dir
        ENV["COSMO_ROOT"] || default_cosmocc_dir
      end

      def reset_paths!
        @mrbc_path = nil
        @libmruby_path = nil
        @include_path = nil
        @lib_path = nil
      end

      private

      def bundled_dir
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

      def default_cosmocc_dir
        File.join(ENV.fetch("HOME"), ".portable-mruby", "cosmocc")
      end

      def cache_dir
        File.join(ENV.fetch("HOME"), ".portable-mruby", "cache")
      end

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

      def ensure_cosmocc
        return if File.exist?(cosmocc_path)

        if ENV["COSMO_ROOT"]
          raise BuildError, "COSMO_ROOT is set but cosmocc not found at #{cosmocc_path}"
        end

        puts "Cosmopolitan toolchain not found."
        puts "Downloading cosmocc (~60MB)..."

        download_cosmocc
      end

      def download_cosmocc
        FileUtils.mkdir_p(default_cosmocc_dir)
        zip_path = File.join(default_cosmocc_dir, "cosmocc.zip")

        download_with_progress(COSMOCC_URL, zip_path)

        puts "Extracting cosmocc..."
        Dir.chdir(default_cosmocc_dir) do
          system("unzip", "-q", "cosmocc.zip") or raise BuildError, "Failed to extract cosmocc"
        end

        FileUtils.rm(zip_path)
        puts "cosmocc installed to #{default_cosmocc_dir}"
      end

      def build_mruby_from_source(source_path)
        source_path = File.expand_path(source_path)

        unless File.directory?(source_path)
          raise BuildError, "mruby source directory not found: #{source_path}"
        end

        unless File.exist?(File.join(source_path, "Rakefile"))
          raise BuildError, "Invalid mruby source directory (no Rakefile): #{source_path}"
        end

        puts "Building mruby from source: #{source_path}"

        build_config_path = File.join(source_path, "build_config", "portable_mruby.rb")
        File.write(build_config_path, generate_build_config)

        Dir.chdir(source_path) do
          env = { "COSMO_ROOT" => cosmocc_dir }

          unless system(env, "rake", "deep_clean", exception: false)
            system(env, "rake", "clean")
          end

          system(env, "rake", "MRUBY_CONFIG=portable_mruby") or
            raise BuildError, "Failed to build mruby"
        end

        build_dir = File.join(source_path, "build", "host")
        @mrbc_path = File.join(build_dir, "bin", "mrbc.com")
        @libmruby_path = File.join(build_dir, "lib", "libmruby.a")
        @lib_path = File.join(build_dir, "lib")

        combined_include = File.join(cache_dir, "include")
        FileUtils.rm_rf(combined_include)
        FileUtils.mkdir_p(combined_include)
        FileUtils.cp_r(File.join(source_path, "include", "."), combined_include)
        FileUtils.cp_r(File.join(build_dir, "include", "."), combined_include)
        @include_path = combined_include

        puts "mruby built successfully from #{source_path}"
      end

      def generate_build_config
        <<~RUBY
          COSMO_ROOT = ENV['COSMO_ROOT']

          unless COSMO_ROOT && File.directory?(COSMO_ROOT)
            raise "COSMO_ROOT environment variable must point to cosmocc directory"
          end

          MRuby::Build.new do |conf|
            conf.cc do |cc|
              cc.command = "\#{COSMO_ROOT}/bin/cosmocc"
              cc.flags = %w[-Os -fno-omit-frame-pointer]
            end

            conf.cxx do |cxx|
              cxx.command = "\#{COSMO_ROOT}/bin/cosmoc++"
              cxx.flags = conf.cc.flags.dup
            end

            conf.linker do |linker|
              linker.command = "\#{COSMO_ROOT}/bin/cosmocc"
              linker.flags = %w[-static]
            end

            conf.archiver do |archiver|
              archiver.command = "\#{COSMO_ROOT}/bin/cosmoar"
            end

            conf.exts.executable = '.com'

            conf.gem core: 'hal-posix-io'
            conf.gem core: 'hal-posix-socket'
            conf.gem core: 'hal-posix-dir'

            conf.gembox 'stdlib'
            conf.gembox 'stdlib-ext'
            conf.gembox 'stdlib-io'
            conf.gembox 'math'
            conf.gembox 'metaprog'

            conf.gem core: 'mruby-bin-mrbc'
          end
        RUBY
      end

      def download_with_progress(url, dest)
        URI.open(url, # rubocop:disable Security/Open
                 content_length_proc: ->(total) { @total_size = total },
                 progress_proc: lambda { |size|
                   if @total_size
                     percent = (size.to_f / @total_size * 100).round(1)
                     print "\rDownloading: #{percent}% (#{size / 1024 / 1024}MB / #{@total_size / 1024 / 1024}MB)"
                   end
                 }) do |remote|
          File.open(dest, "wb") { |f| f.write(remote.read) }
        end
        puts
      end
    end
  end
end
