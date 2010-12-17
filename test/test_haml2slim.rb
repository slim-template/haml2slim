require 'helper'

class TestHaml2Slim < MiniTest::Unit::TestCase
  def setup
    Slim::Engine.default_options[:id_delimiter] = '_'
  end

  def test_templates
    Dir.glob("test/fixtures/*.haml").each do |file|
      assert_valid?(file)
    end
  end

  private

  def assert_valid?(source)
    haml = File.open(source)
    slim = Haml2Slim.convert!(haml)
    assert_equal true, Slim::Validator.validate!(slim)
  end
end