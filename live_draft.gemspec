# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "live_draft/version"

Gem::Specification.new do |s|
  s.name        = "live_draft"
  s.version     = LiveDraft::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Javier Martín"]
  s.email       = ["elretirao@elretirao.net"]
  s.homepage    = ""
  s.summary     = %q{Save drafts without altering the original record}
  s.description = %q{Allows you to have two versions of the same record simultaneously: one "published" and a draft of the planned changes}

  s.add_development_dependency "rspec"

  s.rubyforge_project = "live_draft"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
