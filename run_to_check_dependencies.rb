#!/usr/bin/env ruby

out = STDOUT.clone
STDOUT.reopen "/dev/null"
STDERR.reopen "/dev/null"

$missing = []

def check(name, args, deb_package, expected = 0)
  system("#{name} #{args}")
  $missing << [name, args, deb_package] if $?.exitstatus != expected
end

check("antiword", "-h", "antiword", 0)
check("catdoc", "-h", "catdoc", 1)
check("catppt", "-h", "catdoc", 1)
check("dcraw", "-v", "dcraw", 1)
check("perl", "-e 'use Compress::Zlib'", "libcompress-zlib-perl", 0)
check("exiftool", "-v", "libimage-exiftool-perl", 0)
check("extract", "-v", "extract", 0)
check("html2text", "-help", "html2text", 0)
check("identify", "-version", "imagemagick", 0)
check("inkscape", "--help", "inkscape", 0)
check("md5sum", "--help", "coreutils", 0)
check("mplayer", "-v", "mplayer", 0)
check("pdfinfo", "-v", "poppler-utils", 99)
check("pdftotext", "-v", "poppler-utils", 99)
check("pstotext", "-v", "pstotext", 1)
check("sha1sum", "--help", "coreutils", 0)
check("unhtml", "-h", "unhtml", 1)
check("wc", "--help", "coreutils", 0)
check("xls2csv", "-h", "catdoc", 1)
check("zcat", "-h", "gzip", 0)

$missing.each{|name, args, pkg| out.puts "Missing package #{pkg} (needed for `#{name} #{args}`)" }
out.puts "All dependencies found." if $missing.empty?

exit($missing.empty?)