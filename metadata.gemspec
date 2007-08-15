require './lib/metadata.rb'
require 'rake'

version = Metadata::VERSION
date = Time.now.strftime("%Y-%m-%d")

Gem::Specification.new do |s|
  s.name = 'metadata'
  s.version = version
  s.date = date
  s.summary = 'Metadata extractor'
  s.email = 'ilmari.heikkinen@gmail.com'
  # s.homepage = 'metadata.rubyforge.org'
  s.rubyforge_project = 'metadata'
  s.authors = ['Ilmari Heikkinen']
  s.files = FileList[
    'lib/metadata.rb',
    'lib/metadata/extract.rb',
    'lib/metadata/mime_info.rb',
    'lib/metadata/mime_info_magic.rb',
    'lib/metadata/mp3info.rb'
  ].to_a
  s.executables << 'mdh'
  s.required_ruby_version = '>= 1.8.1'
end
