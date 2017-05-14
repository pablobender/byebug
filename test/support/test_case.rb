require 'minitest'
require 'byebug'
require 'byebug/core'
require 'byebug/interfaces/test_interface'
require 'support/utils'

module Byebug
  #
  # Extends Minitest's base test case and provides defaults for all tests.
  #
  class TestCase < Minitest::Test
    make_my_diffs_pretty!

    include TestUtils
    include Helpers::StringHelper

    def self.before_suite
      Byebug.init_file = '.byebug_test_rc'

      Context.interface = TestInterface.new
      Context.ignored_files = Context.all_files
    end

    #
    # Reset to default state before each test
    #
    def setup
      Byebug.start
      interface.clear

      Byebug.breakpoints.clear if Byebug.breakpoints
    end

    #
    # Cleanup temp files, and dummy classes/modules.
    #
    def teardown
      cleanup_namespace
      clear_example_file

      Byebug.stop
    end

    #
    # Removes test example file and its memoization
    #
    def clear_example_file
      # TODO: Remove the `closed?` check once Ruby 2.2 support is dropped since
      # it seems to be checked internally by `close`.
      example_file.close unless example_file.closed?

      delete_example_file

      @example_file = nil
    end

    #
    # Cleanup main Byebug namespace from dummy test classes and modules
    #
    def cleanup_namespace
      force_remove_const(Byebug, 'ExampleClass')
      force_remove_const(Byebug, 'ExampleModule')
    end

    #
    # Temporary file where code for each test is saved
    #
    def example_file
      @example_file ||= File.new(example_path, 'w+', 0o755)
    end

    #
    # Path to file where test code is saved
    #
    def example_path
      File.join(example_folder, 'byebug_example.rb')
    end

    #
    # Temporary folder where the test file lives
    #
    def example_folder
      @example_folder ||= Dir.tmpdir
    end

    private

    def delete_example_file
      File.unlink(example_file)
    rescue
      # On windows we need the file closed before deleting it, and sometimes it
      # didn't have time to close yet. So retry until we can delete it.
      retry
    end
  end
end
