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
      Rails::Generators.invoke("rest_framework:controller", ["--help"])
    end
  end

  def test_controller_failure
    _suppress_stdout do
      assert_raises(StandardError) do
        Rails::Generators.invoke("rest_framework:controller", ["TEST"])
      end
    end
  end

  def test_controller
    path = "test_api/testa"
    filename = "app/controllers/#{path}_controller.rb"
    _suppress_stdout do
      Rails::Generators.invoke("rest_framework:controller", [path])
    end
    file = File.read(filename)
    expected = <<~END
      class TestApi::TestaController < ApplicationController
        include RESTFramework::ModelControllerMixin
      end
    END
    assert(file)
    assert_equal(file.strip, expected.strip)
    File.delete(filename)
  end

  def test_controller_with_include_base
    path = "test_api/testb"
    filename = "app/controllers/#{path}_controller.rb"
    _suppress_stdout do
      Rails::Generators.invoke("rest_framework:controller", [path, "--include-base"])
    end
    file = File.read(filename)
    expected = <<~END
      class TestApi::TestbController < ApplicationController
        include RESTFramework::BaseControllerMixin
      end
    END
    assert(file)
    assert_equal(file.strip, expected.strip)
    File.delete(filename)
  end

  def test_controller_with_parent_class
    path = "test_api/testc"
    filename = "app/controllers/#{path}_controller.rb"
    _suppress_stdout do
      Rails::Generators.invoke(
        "rest_framework:controller",
        [path, "--parent-class=TestApiController"],
      )
    end
    file = File.read(filename)
    expected = <<~END
      class TestApi::TestcController < TestApiController
        include RESTFramework::ModelControllerMixin
      end
    END
    assert(file)
    assert_equal(file.strip, expected.strip)
    File.delete(filename)
  end
end
