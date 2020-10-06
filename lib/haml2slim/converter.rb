module Haml2Slim
  class Converter
    def initialize(haml)
      @semaphore = false
      @sem_indent = 0
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

      if indent.size <= @sem_indent && !line[0].nil?
        @semaphore = false
      end

      if !@semaphore
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
        elsif
        converted = "#{line}"
      end

      if converted == 'ruby:' || converted == 'javascript:' || converted == 'script'
        @semaphore = true
        @sem_indent = indent.size
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
        if text.empty?
          "#{tag} #{parse_attrs(attrs)}"
        else
          "#{tag} #{parse_attrs(attrs)} #{text}"
        end
      else
        tag_line.sub(/^!=/, '=')
      end
    end

    def parse_attrs(attrs, key_prefix='')
      flag = true
      data_temp = {}
      attrs.gsub!(/:data\s*=>\s*\{([^\}]*)\}/) do
        key = rand(99999).to_s
        data_temp[key] = parse_attrs($1, 'data-')
        ":#{key} => #{key}"
      end


      if flag
        attrs.gsub!(/,?( ?):?"?([^"'{ ]+)"?\s*=>\s*([^,]*)/) do
          space = $1
          key = $2
          value = $3
          wrapped_value = value.to_s =~ /\s+/ ? "(#{value})" : value

          "#{space}#{key_prefix}#{key}=#{wrapped_value}"
        end
        flag = false
      end

      if flag
        attrs.gsub!(/,?( ?):?"?([^"'{ ]+)"?\s*:\s*([^,]*)/) do |v|
          space = $1
          key = $2
          value = $3

          "#{space}#{key_prefix}#{key}=#{value}"
        end
        flag = false
      end

      data_temp.each do |k, v|
        attrs.gsub!("#{k}=#{k}", v)
      end
      attrs.rstrip!
      attrs
    end
  end
end
