require 'optparse'
require 'haml2slim'

module Haml2Slim
  class Command
    def initialize(args)
      @args    = args
      @options = {}
    end

    def run
      @opts = OptionParser.new(&method(:set_opts))
      @opts.parse!(@args)
      process!
      exit 0
    rescue Exception => ex
      raise ex if @options[:trace] || SystemExit === ex
      $stderr.print "#{ex.class}: " if ex.class != RuntimeError
      $stderr.puts ex.message
      $stderr.puts '  Use --trace for backtrace.'
      exit 1
    end

    protected

    def set_opts(opts)
      opts.banner = "Usage: haml2slim INPUT_FILENAME_OR_DIRECTORY [OUTPUT_FILENAME_OR_DIRECTORY] [options]"

      opts.on('--trace', :NONE, 'Show a full traceback on error') do
        @options[:trace] = true
      end

      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end

      opts.on_tail('-v', '--version', 'Print version') do
        puts "Haml2Slim #{Haml2Slim::VERSION}"
        exit
      end

      opts.on('-d', '--delete', 'Delete HAML files') do
        @options[:delete] = true
      end
    end

    def process!
      args = @args.dup

      @options[:input]  = file        = args.shift
      @options[:output] = destination = args.shift

      @options[:input] = file = "-" unless file

      if File.directory?(@options[:input])
        Dir["#{@options[:input]}/**/*.haml"].each { |file| _process(file, destination) }
      else
        _process(file, destination)
      end
    end

    private

    def _process(file, destination = nil)
      require 'fileutils'
      slim_file = file.sub(/\.haml$/, '.slim')

      if File.directory?(@options[:input]) && destination
        FileUtils.mkdir_p(File.dirname(slim_file).sub(@options[:input].chomp('/'), destination))
        slim_file.sub!(@options[:input].chomp('/'), destination)
      else
        slim_file = destination || slim_file
      end

      in_file = if @options[:input] == "-"
                  $stdin
                else
                  File.open(file, 'r')
                end

      @options[:output] = slim_file && slim_file != '-' ? File.open(slim_file, 'w') : $stdout
      @options[:output].puts Haml2Slim.convert!(in_file)
      @options[:output].close

      File.delete(file) if @options[:delete]
    end
  end
end
