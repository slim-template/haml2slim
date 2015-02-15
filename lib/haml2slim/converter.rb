module Haml2Slim
  class Converter
    attr_accessor :filter_indent

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

      if filter_indent && indent.length > filter_indent.length
        return line
      else
        self.filter_indent = nil
      end

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
            when ?:         then self.filter_indent = indent; "#{line[1..-1]}:"
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

      if tag_line_contains_attr = tag_line.match(/([^\{]+)(\{.+\})(.*)/)
        tag, hash, text = *tag_line_contains_attr[1..3]
        "#{tag}*#{hash} #{text}"
      else
        tag_line.sub(/^!=/, '=')
      end
    end
  end
end
