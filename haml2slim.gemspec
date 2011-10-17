# -*- encoding: utf-8 -*-
require File.expand_path("../lib/haml2slim/version", __FILE__)
require "date"

Gem::Specification.new do |s|
  s.name             = "haml2slim"
  s.version          = Haml2Slim::VERSION
  s.date             = Date.today.to_s
  s.authors          = ["Fred Wu"]
  s.email            = ["ifredwu@gmail.com"]
  s.summary          = %q{Haml to Slim converter.}
  s.description      = %q{Convert Haml templates to Slim templates.}
  s.homepage         = %q{http://github.com/fredwu/haml2slim}
  s.extra_rdoc_files = ["README.md"]
  s.rdoc_options     = ["--charset=UTF-8"]
  s.require_paths    = ["lib"]
  s.files            = `git ls-files --  lib/* bin/* README.md`.split("\n")
  s.executables      = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  s.add_dependency "haml", [">= 3.0"]
  s.add_dependency "nokogiri"
  s.add_dependency "ruby_parser"
  s.add_development_dependency "slim", [">= 1.0.0"]
end
