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

      attrs = data_hash_to_placeholder(attrs, type: 'ruby18', data_temp: data_temp)
      attrs = data_hash_to_placeholder(attrs, type: 'ruby19', data_temp: data_temp)

      attrs = hash_to_assignment(attrs, type: 'ruby18', key_prefix: key_prefix)
      attrs = hash_to_assignment(attrs, type: 'ruby19', key_prefix: key_prefix)

      data_temp.each do |k, v|
        attrs.gsub!("#{k}=#{k}", v)
      end

      attrs
    end

    private

    def data_hash_to_placeholder(attrs, type:, data_temp:)
      data_hash_types = {
        'ruby18' => /:data\s*=>\s*\{([^\}]*)\}/,
        'ruby19' => /data:\s*\{([^\}]*)\}/
      }

      attrs.gsub data_hash_types[type] do
        key = rand(99999).to_s
        data_temp[key] = parse_attrs($1, 'data-')
        ":#{key} => #{key}"
      end
    end

    def hash_to_assignment(hash, type:, key_prefix:)
      has_types = {
        'ruby18' => /,?( ?):?"?([^"'{ ]+)"?\s*=>\s*([^,]*)/,
        'ruby19' => /,?( ?)([^"'{ ]+)\:\s*([^,]*)/
      }

      hash.gsub has_types[type] do
        space, key, value = $1, $2, $3
        wrapped_value = value.to_s =~ /\s+/ ? "(#{value})" : value
        "#{space}#{key_prefix}#{key}=#{wrapped_value}"
      end
    end
  end
end
