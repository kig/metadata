require './lib/metadata.rb'
require 'rake'
dir = "#{File.dirname(__FILE__)}/"

version = Metadata::VERSION
date = Time.now.strftime("%Y-%m-%d")

Gem::Specification.new do |s|
  s.name = 'metadata'
  s.version = version
  s.date = date
  s.summary = 'Metadata extractor'
  s.email = 'ilmari.heikkinen@gmail.com'
  s.authors = ['Ilmari Heikkinen']
  s.files = FileList[
    dir + 'lib/metadata.rb',
    dir + 'lib/metadata/extract.rb',
    dir + 'lib/metadata/mime_info.rb',
    dir + 'lib/metadata/mime_info_magic.rb',
    dir + 'lib/metadata/bt.rb'
  ].to_a
  s.executables << 'mdh'
  s.executables << 'chardet'
  s.required_ruby_version = '>= 1.8.1'
  %w(flacinfo-rb wmainfo-rb MP4Info id3lib-ruby apetag).each{|dep|
    s.add_dependency(dep)
  }
end
