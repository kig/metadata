#!/usr/bin/ruby

require './lib/metadata.rb'
require 'fileutils'

dn = "metadata-#{Metadata::VERSION}"
FileUtils.mkdir(dn)
%w(lib bin README INSTALL setup.rb).each{|fn|
  FileUtils.cp_r(fn, dn)
}
`tar zcf #{dn}.tar.gz #{dn}`
FileUtils.rm_r(dn)
s = <<-EOF
tarball: http://dark.fhtr.org/repos/metadata/#{dn}.tar.gz
git: http://dark.fhtr.org/repos/metadata


#{File.read('README')}
EOF
File.open("release_msg-#{Metadata::VERSION}.txt", "w"){|f| f.write s}
