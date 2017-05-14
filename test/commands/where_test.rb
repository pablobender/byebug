# encoding: utf-8

require 'test_helper'

module Byebug
  #
  # Tests commands which deal with backtraces.
  #
  class WhereStandardTest < TestCase
    def program
      strip_line_numbers <<-EOP
         1:  module Byebug
         2:    #
         3:    # Toy class to test backtraces.
         4:    #
         5:    class ExampleClass
         6:      def initialize(l)
         7:        @letter = encode(l)
         8:      end
         9:
        10:      def encode(str)
        11:        to_int(str + 'x') + 5
        12:      end
        13:
        14:      def to_int(str)
        15:        byebug
        16:        str.ord
        17:      end
        18:    end
        19:
        20:    frame = ExampleClass.new('f')
        21:
        22:    frame
        23:  end
      EOP
    end

    def test_where_displays_current_backtrace_with_fullpaths_by_default
      enter 'where'
      debug_code(program)

      expected_output = prepare_for_regexp <<-TXT
        --> #0  Byebug::ExampleClass.to_int(str#String) at #{example_path}:16
            #1  Byebug::ExampleClass.encode(str#String) at #{example_path}:11
            #2  Byebug::ExampleClass.initialize(l#String) at #{example_path}:7
            ͱ-- #3  Class.new(*args) at #{example_path}:20
            #4  <module:Byebug> at #{example_path}:20
            #5  <top (required)> at #{example_path}:1
      TXT

      check_output_includes(*expected_output)
    end

    def test_where_displays_backtraces_using_long_callstyle_by_default
      enter 'where'
      debug_code(program)

      expected_output = prepare_for_regexp <<-TXT
        --> #0  Byebug::ExampleClass.to_int(str#String) at #{example_path}:16
            #1  Byebug::ExampleClass.encode(str#String) at #{example_path}:11
            #2  Byebug::ExampleClass.initialize(l#String) at #{example_path}:7
            ͱ-- #3  Class.new\(*args) at #{example_path}:20
            #4  <module:Byebug> at #{example_path}:20
            #5  <top (required)> at #{example_path}:1
      TXT

      check_output_includes(*expected_output)
    end

    def test_where_displays_backtraces_using_short_callstyle
      enter 'set callstyle short', 'where', 'set callstyle long'
      debug_code(program)

      expected_output = prepare_for_regexp <<-TXT
        --> #0  to_int(str) at #{example_path}:16
            #1  encode(str) at #{example_path}:11
            #2  initialize(l) at #{example_path}:7
            ͱ-- #3  new(*args) at #{example_path}:20
            #4  <module:Byebug> at #{example_path}:20
            #5  <top (required)> at #{example_path}:1
      TXT

      check_output_includes(*expected_output)
    end

    def test_where_displays_instance_exec_block_frames
      enter 'where'
      program = strip_line_numbers <<-EOP
         1:  module Byebug
         2:    class Byebug::ExampleClass
         3:      def foo
         4:        Object.new.instance_exec do
         5:          byebug
         6:        end
         7:      end
         8:     end
         9:
        10:    Byebug::ExampleClass.new.foo
        11:  end
      EOP
      debug_code(program)

      expected_output = prepare_for_regexp <<-TXT
        --> #0  block in Byebug::ExampleClass.block in foo at #{example_path}:6
            #1  BasicObject.instance_exec(*args) at #{example_path}:4
            #2  Byebug::ExampleClass.foo at #{example_path}:4
            #3  <module:Byebug> at #{example_path}:10
            #4  <top (required)> at #{example_path}:1
      TXT

      check_output_includes(*expected_output)
    end
  end

  #
  # Tests dealing with backtraces when the path being debugged is not deeply
  # nested.
  #
  # @note We skip this tests in Windows since the paths in this CI environment
  #   are usually very deeply nested.
  #
  unless /cygwin|mswin|mingw/ =~ RUBY_PLATFORM
    class WhereWithNotDeeplyNestedPathsTest < WhereStandardTest
      def test_where_displays_current_backtrace_w_shorpaths_if_fullpath_disabled
        enter 'set nofullpath', 'where', 'set fullpath'
        debug_code(program)

        expected_output = prepare_for_regexp <<-TXT
          --> #0  Byebug::ExampleClass.to_int(str#String) at #{example_path}:16
              #1  Byebug::ExampleClass.encode(str#String) at #{example_path}:11
              #2  Byebug::ExampleClass.initialize(l#String) at #{example_path}:7
              ͱ-- #3  Class.new(*args) at #{example_path}:20
              #4  <module:Byebug> at #{example_path}:20
              #5  <top (required)> at #{example_path}:1
        TXT

        check_output_includes(*expected_output)
      end
    end
  end

  #
  # Tests dealing with backtraces when the path being debugged is deeply nested.
  #
  class WhereWithDeeplyNestedPathsTest < WhereStandardTest
    def setup
      @example_parent_folder = Dir.mktmpdir(nil)
      @example_folder = Dir.mktmpdir(nil, @example_parent_folder)

      super
    end

    def teardown
      super

      FileUtils.remove_dir(@example_parent_folder, true)
    end

    def test_where_displays_current_backtrace_w_shorpaths_if_fullpath_disabled
      enter 'set nofullpath', 'where', 'set fullpath'
      debug_code(program)

      expected_output = prepare_for_regexp <<-TXT
        --> #0  Byebug::ExampleClass.to_int(str#String) at ...
            #1  Byebug::ExampleClass.encode(str#String) at ...
            #2  Byebug::ExampleClass.initialize(l#String) at ...
            ͱ-- #3  Class.new(*args) at ...
            #4  <module:Byebug> at ...
            #5  <top (required)> at ...
      TXT

      check_output_includes(*expected_output)
    end
  end
end
