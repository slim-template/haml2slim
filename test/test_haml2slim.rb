require 'helper'

class TestHaml2Slim < MiniTest::Unit::TestCase
  def test_standard
    assert_valid?(:standard)
  end

  private

  def assert_valid?(source)
    haml = File.open("test/fixtures/#{source}.haml")
    slim = Haml2Slim.convert!(haml)
    assert_equal true, Slim::Validator.validate!(slim)
  end

  def haml2slim(haml)
    Haml2Slim.convert!(haml)
  end
end