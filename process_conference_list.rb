#!/usr/bin/ruby

bullet_re = /^\s*[0-9#*]+\.?\s*/
lines = STDIN.readlines

conferences_by_topic = []
lines.each{|l|
  l = l.gsub(/\[.*\]/, "")
  l = l.strip
  if l.size < 3
    nil
  elsif l =~ bullet_re
    # first word
    l = l.sub(bullet_re, "").strip
    short = l[/^[a-z0-9\&\-\/\(\)]+\s*(-|\342\200\224\)?\s*/i]
    if short and (short =~ /-/ or short.scan(/[A-Z]/).size >= 2) # ooh, an acronym
      name = l[short.length..-1]
      short = short.strip.gsub(/\s*-$/, "")
      name = short if name.empty?
      pat = /\b(#{Regexp.escape(short)}|#{Regexp.escape(name)})\b/u
    else
      name = l
      pat = /\b#{Regexp.escape(name)}\b/u
    end
    conferences_by_topic.last[1] << "    [#{pat.inspect}, #{name.dump}, []]"
  else
    conferences_by_topic << [l, []]
  end
}
conferences_by_topic.each{|topic, lines|
  puts "  # #{topic}"
  puts "  CONFERENCES.push(*( [\n"
  puts lines.join(",\n")
  puts "  ].map{|a| a[-1] = [Topics::#{topic.upcase.gsub(/[^a-zA-Z]+/, "_")}]+a[-1]; a }))\n"
}
