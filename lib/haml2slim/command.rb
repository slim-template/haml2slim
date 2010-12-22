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
      opts.on('-s', '--stdin', :NONE, 'Read input from standard input instead of an input file') do
        @options[:input] = $stdin
      end

      opts.on('-o', '--output FILENAME', :NONE, 'Output file destination') do |filename|
        @options[:output] = filename
      end

      opts.on('--trace', :NONE, 'Show a full traceback on error') do
        @options[:trace] = true
      end

      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end

      opts.on_tail('-v', '--version', 'Print version') do
        puts "Slim #{Haml2Slim::VERSION}"
        exit
      end
    end

    def process!
      @files = @args.dup

      unless @options[:input]
        file = @files.shift
        if file
          @options[:file]  = file
          @options[:input] = file
        else
          @options[:file]  = 'STDIN'
          @options[:input] = $stdin
        end
      end

      if File.directory?(@options[:file])
        Dir["#{@options[:file]}/**/*.haml"].each { |file| _process(file) }
      else
        _process(file)
      end
    end

    private

    def _process(file)
      slim_file = (File.file?(@options[:file]) ? @options[:output] : false) || file.sub(/\.haml$/, '.slim')
      @options[:output] = file ? File.open(slim_file, 'w') : $stdout
      @options[:output].puts Haml2Slim.convert!(File.open(file, 'r'))
      @options[:output].close
    end
  end
end