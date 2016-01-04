require 'helper'
require 'tmpdir'

class TestHaml2Slim < MiniTest::Unit::TestCase
  def setup
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

  def test_convert_file_to_stdout
    File.open(haml_file, "w") do |f|
      f.puts "%p\n  %h1 Hello"
    end

    IO.popen("bin/haml2slim #{haml_file} -", "r") do |f|
      assert_equal "p\n  h1 Hello\n", f.read
    end
  end

  def test_convert_stdin_to_stdout
    File.open(haml_file, "w") do |f|
      f.puts "%p\n  %h1 Hello"
    end

    IO.popen("cat #{haml_file} | bin/haml2slim", "r") do |f|
      assert_equal "p\n  h1 Hello\n", f.read
    end
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

  def test_delete_haml_file
    `bin/haml2slim #{haml_file} -d`
    assert_equal false, File.exist?(haml_file)
  end

  def test_hash_convert
    haml = '%a{:title => 1 + 1, :href => "/#{test_obj.method}", :height => "50px", :width => "50px"}'
    slim = 'a title=(1 + 1) href="/#{test_obj.method}" height="50px" width="50px"'
    assert_haml_to_slim haml, slim
  end

  def test_data_attributes_convert
    haml = '%a{:href => "test", :data => {:param1 => var, :param2 => 1 + 1, :param3 => "string"}}'
    slim = 'a href="test" data-param1=var data-param2=(1 + 1) data-param3="string"'
    assert_haml_to_slim haml, slim
  end

  def test_new_syntax_hash_convert
    haml = '%a{title: 1 + 1, href: "/#{test_obj.method}", height: "50px", width: "50px"}'
    slim = 'a title=(1 + 1) href="/#{test_obj.method}" height="50px" width="50px"'
    assert_haml_to_slim haml, slim
  end

  def test_no_html_escape_predicate
    haml = '!= method_call'
    slim = '== method_call'
    assert_haml_to_slim haml, slim
  end

  def test_no_html_escape_predicate2
    haml = '%span!= method_call'
    slim = 'span== method_call'
    assert_haml_to_slim haml, slim
  end

  private

  def assert_haml_to_slim(actual_haml, expected_slim)
    File.open(haml_file, "w") do |f|
      f.puts actual_haml
    end

    IO.popen("cat #{haml_file} | bin/haml2slim", "r") do |f|
      assert_equal expected_slim, f.read.strip
    end
  end

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
    assert_instance_of String, Slim::Engine.new.call(slim.to_s)
  end
end
