module Metadata
module ReferenceGuesser
extend self

  def guess_references(str)
    references = str.scan(/^\s*(\d*\.)*\d*\s*(References|Citations)\s*\n(.+)/im).flatten[2]
    if references
      parse_references(references)
    else
      nil
    end
  end

  def parse_references(refs)
    data = Metadata.remove_ligatures(refs)

    cites = data.scan(/(.+?((\[)|((19|20)\d\d\.)))/).map{|s| s[0].strip.gsub(/\A[^\]]+\]|\[\Z/,'') }
    cites2 = data.scan(/\[[^\]]+\]([^\[]+)/).map{|s| s[0].strip }

    # use the one with fewer nearly-empty strings
    c1_lens = cites.inject(Hash.new(0)){|s,i| s[i.length / 20] += 1; s}
    c2_lens = cites2.inject(Hash.new(0)){|s,i| s[i.length / 20] += 1; s}
    c1_med_len = (c1_lens.max{|a,b| a[1] <=> b[1] } || [-1])[0]
    c2_med_len = (c2_lens.max{|a,b| a[1] <=> b[1] } || [-1])[0]
    if c1_med_len < c2_med_len
      cites = cites2
    end

    name_re = /\b([[:upper:]]((\.([[:upper:]]\.)*)|([[:lower:]]+))[-\s]([[:upper:]]((\.)|([[:lower:]]+))[-\s]*)+)/um
    names_re = /\b(((([[:upper:]]((\.([[:upper:]]\.)*)|([[:lower:]]+))[-\s]([[:upper:]]((\.)|([[:lower:]]+))[-\s]*)+)|Anon\.),?\s*(and)?\s*(et al)?)+)/um
    new_chapter_re = /\b\d+\. [A-Z]{4,50}\b/
    refs = []
    cites.each do |c|
      if c.length > 400
        done = true
      elsif c =~ new_chapter_re
        c = c.split(new_chapter_re).first
        done = true
      end
      cite = c.gsub(/\n\s*/m, ' ').gsub(/['´`']/,'')
      ar = cite.scan(/([^"“”]+)["“”]([^"“”]+)["“”](.+)/um)
      ar_title = nil
      unless ar.empty?
        ar_title = ar[0][1]
        cite[ar_title] = ''
        cite.gsub!(/["“”]/,'')
      end
      authors = cite.scan(names_re).map{|n|n[0]}.reject{|s| not (s.strip =~ /([[:lower:]]|\.)$/) }
      author_str = ""
      unless authors.empty?
        author_str = authors.sort_by{|a| [-a.count(','), -a.count('.')] }.first
        cite[author_str] = ''
      end
      cite.gsub!(/\A\s*\.|\.\s*\Z/, '')
      cite.strip!
      a,b = cite.split(/[\.\?\!]/, 2).map{|s| s.strip }
      if a =~ /\d{4}/ or a =~ /pages/
        title, rest = b, a
        rest = a
      else
        title, rest = a, b
      end
      auths = author_str.scan(name_re).map{|n| n[0].strip }
      refs << {
        'title' => ar_title || title,
        'href' => cite.scan(%r{http://\S+})[0],
        'rest' => auths.join(", ") + " - " + rest.to_s,
        'authors' => auths,
        'published_in' => rest
      }
      break if done
    end
    refs.delete_if{|r| r['title'].to_s.strip.empty? }
    refs
  end

end
end