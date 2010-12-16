require 'haml2slim/version'
require 'haml2slim/converter'

module Haml2Slim
  def self.convert!(input)
    Converter.new(input)
  end
end