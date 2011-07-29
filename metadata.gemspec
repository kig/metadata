# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "metadata/version"

Gem::Specification.new do |s|
  s.name        = "metadata"
  s.version     = Metadata::VERSION
  s.authors     = ["Ilmari Heikkinen"]
  s.email       = ["ilmari.heikkinen@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Metadata extractor}
  s.description = %q{Metadata extractor}

  s.rubyforge_project = "metadata"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  %w(flacinfo-rb wmainfo-rb MP4Info id3lib-ruby apetag mini_magick).each do |dep|
    s.add_dependency(dep)
  end
end

