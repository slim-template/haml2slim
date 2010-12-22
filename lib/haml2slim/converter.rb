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

      converted = case line[0, 2]
        when '&=' then line.sub(/^&=/, '==')
        when '!=' then line.sub(/^!=/, '=')
        when '-#' then line.sub(/^-#/, '/')
        else
          case line[0]
            when ?%, ?., ?# then parse_tag(line)
            when ?:         then "#{line[1..-1]}:"
            when ?!         then line.sub(/^!!!/, '! doctype')
            when ?-, ?=     then line
            when ?~         then line.sub(/^~/, '=')
            when ?/         then line
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

      if tag_line_contains_attr = tag_line.match(/(.+)\{(.+)\}/)
        tag, attrs = *tag_line_contains_attr[1..2]

        attrs.gsub!(/,?( ?):?"?([^"'{ ]+)"? ?=> ?/, '\1\2=')
        attrs.gsub!(/=([^"']+)(?: |$)/, '=(\1)')

        "#{tag} #{attrs}"
      else
        tag_line
      end
    end
  end
end