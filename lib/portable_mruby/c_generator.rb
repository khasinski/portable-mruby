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

      {{BYTECODE_ARRAYS}}

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

          ARGV_val = mrb_ary_new_capa(mrb, argc > 1 ? argc - 1 : 0);
          for (i = 1; i < argc; i++) {
              mrb_ary_push(mrb, ARGV_val, mrb_str_new_cstr(mrb, argv[i]));
          }
          mrb_define_global_const(mrb, "ARGV", ARGV_val);
          mrb_gv_set(mrb, mrb_intern_lit(mrb, "$0"), mrb_str_new_cstr(mrb, argv[0]));

          for (i = 0; bytecode_files[i].data != NULL; i++) {
              mrb_load_irep(mrb, bytecode_files[i].data);

              if (mrb->exc) {
                  mrb_print_error(mrb);
                  return_value = 1;
                  break;
              }
          }

          /* Call __main__ if defined (optional entry point) */
          /* Supports both __main__(argv) and __main__() signatures */
          if (!mrb->exc && mrb_respond_to(mrb, mrb_top_self(mrb), mrb_intern_lit(mrb, "__main__"))) {
              mrb_value full_argv = mrb_ary_new_capa(mrb, argc);
              for (i = 0; i < argc; i++) {
                  mrb_ary_push(mrb, full_argv, mrb_str_new_cstr(mrb, argv[i]));
              }
              /* Try calling with argv first */
              mrb_funcall(mrb, mrb_top_self(mrb), "__main__", 1, full_argv);
              /* If ArgumentError (wrong number of args), retry without args */
              if (mrb->exc && mrb_obj_is_kind_of(mrb, mrb_obj_value(mrb->exc), mrb_class_get(mrb, "ArgumentError"))) {
                  mrb->exc = NULL;
                  mrb_funcall(mrb, mrb_top_self(mrb), "__main__", 0);
              }
              if (mrb->exc) {
                  mrb_print_error(mrb);
                  return_value = 1;
              }
          }

          mrb_close(mrb);
          return return_value;
      }
    C

    def initialize(bytecode_files)
      @bytecode_files = bytecode_files
    end

    def generate
      RUNTIME_TEMPLATE
        .gsub("{{BYTECODE_ARRAYS}}", generate_bytecode_arrays)
        .gsub("{{BYTECODE_ENTRIES}}", generate_bytecode_entries)
    end

    private

    def generate_bytecode_arrays
      @bytecode_files.each_with_index.map do |file_info, idx|
        bytes = File.binread(file_info[:mrb_path]).bytes
        byte_lines = bytes.each_slice(16).map do |slice|
          "    " + slice.map { |b| format("0x%02x", b) }.join(", ")
        end

        <<~C
          static const uint8_t bytecode_#{idx}[] = {
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
