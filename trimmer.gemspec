# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "trimmer/version"

Gem::Specification.new do |s|
  s.name        = "trimmer"
  s.license     = "MIT"
  s.version     = Trimmer::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Pablo Villalba", "Saimon Moore"]
  s.email       = ["pablo@teambox.com", "saimon@teambox.com"]
  s.homepage    = "https://github.com/teambox/trimmer"
  s.summary = %q{Rack endpoint to make templates and i18n translations available in javascript}

  s.rubyforge_project = "trimmer"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency 'activesupport', '>= 3.0'
  s.add_dependency 'rack', '~> 1.1'
  s.add_dependency 'i18n', '~> 0.6.0'
  s.add_dependency 'tilt', '~> 1.3.3'
  s.add_development_dependency 'test-spec', '~> 0.9.0'
  s.add_development_dependency 'haml', '~> 3.0.25'
  s.add_development_dependency 'json', '~> 1.1'
end
