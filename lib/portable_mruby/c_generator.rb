# frozen_string_literal: true

module PortableMruby
  class CGenerator
    RUNTIME_TEMPLATE = <<~'C'
      #include <mruby.h>
      #include <mruby/array.h>
      #include <mruby/compile.h>
      #include <mruby/irep.h>
      #include <mruby/string.h>
      #include <mruby/variable.h>
      #include <stdio.h>
      #include <stdlib.h>

      /* Embedded bytecode */
      {{BYTECODE_ARRAYS}}

      /* Bytecode registry */
      static const struct {
          const uint8_t *data;
          size_t size;
          const char *name;
      } bytecode_files[] = {
      {{BYTECODE_ENTRIES}}
          {NULL, 0, NULL}
      };

      int main(int argc, char **argv) {
          mrb_state *mrb;
          mrb_value ARGV_val;
          int i;
          int return_value = 0;

          mrb = mrb_open();
          if (!mrb) {
              fprintf(stderr, "Error: Failed to initialize mruby\n");
              return 1;
          }

          /* Set up ARGV */
          ARGV_val = mrb_ary_new_capa(mrb, argc > 1 ? argc - 1 : 0);
          for (i = 1; i < argc; i++) {
              mrb_ary_push(mrb, ARGV_val, mrb_str_new_cstr(mrb, argv[i]));
          }
          mrb_define_global_const(mrb, "ARGV", ARGV_val);

          /* Set $0 to program name */
          mrb_gv_set(mrb, mrb_intern_lit(mrb, "$0"), mrb_str_new_cstr(mrb, argv[0]));

          /* Load and execute all bytecode files in order */
          for (i = 0; bytecode_files[i].data != NULL; i++) {
              mrb_load_irep(mrb, bytecode_files[i].data);

              if (mrb->exc) {
                  mrb_print_error(mrb);
                  return_value = 1;
                  break;
              }
          }

          mrb_close(mrb);
          return return_value;
      }
    C

    def initialize(bytecode_files)
      @bytecode_files = bytecode_files
    end

    # Generate complete C source with embedded bytecode
    def generate
      arrays = generate_bytecode_arrays
      entries = generate_bytecode_entries

      RUNTIME_TEMPLATE
        .gsub("{{BYTECODE_ARRAYS}}", arrays)
        .gsub("{{BYTECODE_ENTRIES}}", entries)
    end

    private

    def generate_bytecode_arrays
      @bytecode_files.each_with_index.map do |file_info, idx|
        bytes = File.binread(file_info[:mrb_path]).bytes
        symbol = "bytecode_#{idx}"

        byte_lines = bytes.each_slice(16).map do |slice|
          "    " + slice.map { |b| format("0x%02x", b) }.join(", ")
        end

        <<~C
          /* #{file_info[:name]} */
          static const uint8_t #{symbol}[] = {
          #{byte_lines.join(",\n")}
          };
        C
      end.join("\n")
    end

    def generate_bytecode_entries
      @bytecode_files.each_with_index.map do |file_info, idx|
        size = File.size(file_info[:mrb_path])
        %(    {bytecode_#{idx}, #{size}, "#{file_info[:name]}"},)
      end.join("\n")
    end
  end
end
