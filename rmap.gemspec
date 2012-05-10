# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rmap/version"

Gem::Specification.new do |s|
  s.name        = "rmap"
  s.version     = Rmap::VERSION
  s.authors     = ["Jody Salt"]
  s.email       = ["jody@jodysalt.com"]
  s.homepage    = "https://github.com/jodysalt/rmap"
  s.summary     = "A simple yet powerful object relational mapper (ORM)."

  s.rubyforge_project = "rmap"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "mysql2", "~> 0"
  s.add_dependency "json", "~> 1"
  s.add_dependency "ripl", "~> 0"
  s.add_dependency "ripl-multi_line", "~> 0"
  
end
