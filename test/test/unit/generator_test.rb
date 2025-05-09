require "test_helper"
require "fileutils"

class GeneratorTest < Minitest::Test
  def _suppress_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original_stdout
  end

  def test_controller_help
    _suppress_stdout do
      Rails::Generators.invoke("rest_framework:controller", [ "--help" ])
    end
  end

  def test_controller_failure
    _suppress_stdout do
      assert_raises(StandardError) do
        Rails::Generators.invoke("rest_framework:controller", [ "TEST" ])
      end
    end
  end

  def test_controller
    path = "api/test/testa"
    filename = "app/controllers/#{path}_controller.rb"
    _suppress_stdout do
      Rails::Generators.invoke("rest_framework:controller", [ path ])
    end
    file = File.read(filename)
    expected = <<~END
      class Api::Test::TestaController < ApplicationController
        include RESTFramework::ModelControllerMixin
      end
    END
    assert(file)
    assert_equal(file.strip, expected.strip)
    File.delete(filename)
  end

  def test_controller_with_include_base
    path = "api/test/testb"
    filename = "app/controllers/#{path}_controller.rb"
    _suppress_stdout do
      Rails::Generators.invoke("rest_framework:controller", [ path, "--include-base" ])
    end
    file = File.read(filename)
    expected = <<~END
      class Api::Test::TestbController < ApplicationController
        include RESTFramework::BaseControllerMixin
      end
    END
    assert(file)
    assert_equal(file.strip, expected.strip)
    File.delete(filename)
  end

  def test_controller_with_parent_class
    path = "api/test/testc"
    filename = "app/controllers/#{path}_controller.rb"
    _suppress_stdout do
      Rails::Generators.invoke(
        "rest_framework:controller",
        [ path, "--parent-class=Api::TestController" ],
      )
    end
    file = File.read(filename)
    expected = <<~END
      class Api::Test::TestcController < Api::TestController
        include RESTFramework::ModelControllerMixin
      end
    END
    assert(file)
    assert_equal(file.strip, expected.strip)
    File.delete(filename)
  end
end
