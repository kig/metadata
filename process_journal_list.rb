#!/usr/bin/ruby

bullet_re = /^\s*[0-9#*]+\.?\s*/
lines = STDIN.readlines

puts "  JOURNALS.push(*( [\n"
puts lines.map{|l|
  l = l.gsub(/\[.*\]/, "")
  l = l.strip
  if l.size < 3 or not l =~ bullet_re
    nil
  else
    l = l.sub(/\s*(\(.*)?$/, "\", []]")
    l = l.sub(bullet_re, "    [\"")
    l
  end
}.compact.join(",\n")
puts "  ].map{|a| a[-1] = []+a[-1]; a }))"
