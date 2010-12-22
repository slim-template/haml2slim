require 'helper'
require 'tmpdir'

class TestHaml2Slim < MiniTest::Unit::TestCase
  def setup
    Slim::Engine.default_options[:id_delimiter] = '_'
    create_haml_file
  end

  def teardown
    cleanup_tmp_files
  end

  Dir.glob("test/fixtures/*.haml").each do |file|
    define_method("test_template_#{File.basename(file, '.haml')}") do
      assert_valid?(file)
    end
  end

  def test_convert_file
    `bin/haml2slim #{haml_file}`
    assert_equal true, slim_file?
  end

  def test_convert_file_to_destination
    slim_path = File.join(tmp_dir, "a.slim")
    `bin/haml2slim #{haml_file} #{slim_path}`
    assert_equal true, slim_file?(slim_path)
  end

  def test_convert_directory
    `bin/haml2slim #{tmp_dir}`
    assert_equal true, slim_file?
  end

  def test_convert_directory_to_destination
    slim_path = Dir.mktmpdir("haml2slim_2.")
    `bin/haml2slim #{tmp_dir} #{slim_path}`
    assert_equal true, slim_file?(File.join(slim_path, "dummy.slim"))
    FileUtils.rm_rf(slim_path)
  end

  private

  def tmp_dir
    @tmp_dir ||= Dir.mktmpdir("haml2slim.")
  end

  def create_haml_file
    `touch #{haml_file}`
  end

  def haml_file
    File.join(tmp_dir, "dummy.haml")
  end

  def slim_file?(path = nil)
    File.file?(path || File.join(tmp_dir, "dummy.slim"))
  end

  def cleanup_tmp_files
    FileUtils.rm_rf(tmp_dir)
  end

  def assert_valid?(source)
    haml = File.open(source)
    slim = Haml2Slim.convert!(haml)
    assert_equal true, Slim::Validator.validate!(slim)
  end
end