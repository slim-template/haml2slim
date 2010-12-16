require 'optparse'
require 'haml2slim/version'
require 'haml2slim/converter'

module Haml2Slim
  class Command
    def initialize(args)
      @args    = args
      @options = {}
    end

    def run
      @opts = OptionParser.new(&method(:set_opts))
      @opts.parse!(@args)
      process
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

    def process
      args = @args.dup
      unless @options[:input]
        file = args.shift
        if file
          @options[:file]  = file
          @options[:input] = File.open(file, 'r')
        else
          @options[:file]  = 'STDIN'
          @options[:input] = $stdin
        end
      end

      unless @options[:output]
        file = args.shift || file.sub(/\.haml$/, '.slim')
        @options[:output] = file ? File.open(file, 'w') : $stdout
      end

      @options[:output].puts Haml2Slim::Converter.new(@options[:input])
    end
  end
end