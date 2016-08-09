require 'securerandom'
module Haml2Slim
  class Converter
    def initialize(haml)
      @slim = ""

      haml.each_line do |line|
        @slim << parse_line(line)
      end
    end

    def to_s
      @slim
    end

    def parse_line(line)
      indent = line[/^[ \t]*/]
      line.strip!

      # removes the HAML's whitespace removal characters ('>' and '<')
      line.gsub!(/(>|<)$/, '')

      converted = case line[0, 2]
        when '&=' then line.sub(/^&=/, '==')
        when '!=' then line.sub(/^!=/, '==')
        when '-#' then line.sub(/^-#/, '/')
        when '#{' then line
        else
          case line[0]
            when ?%, ?., ?# then parse_tag(line)
            when ?:         then "#{line[1..-1]}:"
            when ?!         then line == "!!!" ? line.sub(/^!!!/, 'doctype html') : line.sub(/^!!!/, 'doctype')
            when ?-, ?=     then line
            when ?~         then line.sub(/^~/, '=')
            when ?/         then line.sub(/^\//, '/!')
            when ?\         then line.sub(/^\\/, '|')
            when nil        then ""
            else "| #{line}"
          end
      end

      if converted.chomp!(' |')
        converted.sub!(/^\| /, '')
        converted << ' \\'
      end

      "#{indent}#{converted}\n"
    end

    def parse_tag(tag_line)
      tag_line.sub!(/^%/, '')
      tag_line.sub!(/^(\w+)!=/, '\1==')

      if tag_line_contains_attr = tag_line.match(/([^\{]+)\{(.+)\}(.*)/)
        tag, attrs, text = *tag_line_contains_attr[1..3]
        "#{tag} #{parse_attrs(attrs)} #{text}"
      else
        tag_line.sub(/^!=/, '=')
      end
    end

    def parse_attrs(attrs, key_prefix='')
      data_temp = {}
      # binding.pry if attrs == "type: 'button', class: 'close', data: { dismiss: 'modal' }"
      attrs.gsub!(/(\s|\A|,)(\b[^{}:,=>\s]+)(:)/) do
        "#{$1}:#{$2} =>"
      end

      attrs.gsub!(/\((.*):(.*)\s=>\s(.*)\)/) do
        "(#{$1}#{$2}: #{$3})"
      end

      attrs.gsub!(/\((\s)/, '(')
      attrs.gsub!(/\s\)/, ')')

      attrs.gsub!(/:([^{}:,=>]+\w)\s*=>\s*\{([^\}]*)\}/) do
        key = SecureRandom.hex # Creates uniq numbers this way
        data_temp[key] = { key: $1, value: $2 }
        ":#{key} => #{key}"
      end
      data_temp.each do |key, values|
        data_temp[key] = parse_attrs(values[:value], "#{values[:key]}-")
      end

      attrs.gsub!(/^\s/, '')
      attrs.gsub!(/\s$/, '')

      attrs.gsub!(/,?( ?):?"?([^"'{ ]+)"?\s*=>\s*([^,]*)/) do
        space = $1
        key = $2
        value = $3

        "#{space}#{key_prefix}#{key}=#{wrapped_value(value)}"
      end

      data_temp.each do |k, v|
        attrs.gsub!("#{k}=#{k}", v)
      end
      attrs
    end

    def wrapped_value(value)
      value = value.to_s
      return value if value =~ /('|").*('|")/
      return value if value =~ /(\().*(\))/
      return "(#{value})" if value =~ /\s+/
      value
    end
  end
end
