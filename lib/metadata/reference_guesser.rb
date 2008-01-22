module Metadata
module ReferenceGuesser
extend self


  # ref_tail = extract_references_tail(text)
  # refs = cut_off_post_ref_part(ref_tail)
  # entries = split_into_reference_entries(refs)
  # good_entries = entries.find_all{|entry| good_reference?(entry) }
  # good_entries.map{|entry| parse_entry(entry) }

  def guess_references(str)
    references = str.scan(/^\s*(\d*\.)*\d*\s*(References|Citations)\s*\n(.+)/im).flatten[2]
    if references
      parse_references(references)
    else
      nil
    end
  end
  
  def parse_references(text)
    refs = []
    data = Metadata.remove_ligatures(text).gsub(/\[[^\]]*\]/, ' ')
    cites = extract_author_list_rest_pairs(data)
    cites.each do |authors, rest|
      href = rest.scan(%r{http://\S+})[0]
      title,rest = extract_title(rest)
      refs << {
        'title' => title.strip,
        'href' => href,
        'authors' => authors,
        'published_in' => rest.to_s.strip.chomp(".")
      }
    end
    refs.delete_if{|r| r['title'].to_s.strip.empty? }
    refs
  end

  def extract_title(rest)
    publishers = /\A\s*(in proc|ACM|MIT|proceeding|proc|conference|[a-z]+ press|addison|kluwer|pearson|mcgraw\-hill)/i
    rest.gsub!(/\A\s*(\d{1,3}\.)\s*/, '')
    quotes = '“"”'
    quote_re = /\s*[#{quotes}]([^#{quotes}]+)[#{quotes}]\s*/um
    title = rest.scan(quote_re).flatten.first
    if title
      rest = rest.sub(quote_re, ' ')
      return [title, rest]
    end
    period = rest =~ /\./
    mark = rest =~ /[\?\!]/
    comma = rest =~ /\,/
    if mark and (!period or mark < period) # screwy title
      title = rest[0..mark]
      rest = rest[mark+1..-1]
      unless rest =~ publishers
        tr, rest = extract_title(rest)
        title << tr
      end
    elsif comma and (!period or (comma < period and rest[comma+1..-1] =~ /\s*[A-Z]/))
      title = rest[0...comma]
      rest = rest[comma+1..-1]
      unless rest =~ publishers
        tr, rest = extract_title(rest)
        title << tr
      end
    elsif period
      title,rest = rest.split(".",2)
    else
      title = rest
      rest = ''
    end
    [title, rest]
  end

  def extract_author_list_rest_pairs(refs)
    s = refs.split(/\n(\d+\.)+\s+[A-Z]+\n/m).first

    last_name = /(\b(((de|van|von)\s)?[A-Z][a-z]+|-[, ]|Anon\.?|et al\.?))(,|\b|\s+)/
    first_name = /(\b(([A-Z]\.)+|-\.|[A-Z]\.?))(,|\b|\s+)/
    fl = s =~ last_name
    ff = s =~ first_name
    if fl and ff
      order = (ff > fl ? :last_name_first : :first_name_first)
      names_re = (ff > fl ? last_name : first_name)
    else
      return []
    end
    year_re = /\s(19|20)\d{2}(\)?\.|,(\s*((pages|pp\.?):? \S+))?)/u
    arr = []
    start = [fl, ff].min
    return arr unless start
    if s[0...start].to_s.strip.size < 10
      s[0...start] = ''
      while s.size > 0
        names = extract_names(s, order)
        s.gsub!(/\A\s*[\,\.]\s*/, '')
        start = ((s =~ year_re) || s.length)+6
        rest = s[0...start]
        s[0...start] = ''
        start = (s =~ names_re)
        s[0...(start||s.length)] = ''
        arr << [names, rest]
      end
    else
      while s.size > 0
        rest = s[0...start]
        s[0...start] = ''
        names = extract_names(s, order)
        start = ((s =~ names_re) || s.length)
        arr << [names, rest]
      end
    end
    arr
  end

  def extract_names(s, order)
    names = []
    loop do
      f, l = extract_name(s, order)
      if f and l and f[0]
        names << [f.map{|n| n[0]}, l[0]].join(" ")
      else
        fo = (f || []).map{|n| n[1]}
        lo = (l || [])[1]
        s.sub!(/\A/, (order == :first_name_first ? "#{fo}#{lo}" : "#{lo}#{fo}"))
        break
      end
    end
    names
  end

  def extract_name(s, order)
    first_name = []
    last_name = nil
    if order == :first_name_first
      while n = extract_first_name(s)
        first_name << n
      end
      last_name = extract_last_name(s)
    else
      last_name = extract_last_name(s)
      while n = extract_first_name(s)
        first_name << n
      end
    end
    [first_name, last_name]
  end

  def extract_first_name(s)
    first_name = /\A\s*(\b((-?[A-Z]\.)+|-\.))(,|\b|\s+)(\s*and\s)?/m
    if s =~ first_name
      fn = s[first_name]
      s[0,fn.size] = ''
      [fn.gsub(/(,|\b|\s+)(\s*and\s)?\Z/, '').strip, fn]
    else
      nil
    end
  end

  def extract_last_name(s)
    last_name = /\A\s*(\b(((de|van|von)\s)?([A-Z][a-z’'`']+)+|-[, ]|Anon\.?|et al\.?))(,|\b|\s+)(\s*and\s)?/m
    if s =~ last_name
      fn = s[last_name]
      s[0,fn.size] = ''
      [fn.gsub(/(,|\b|\s+)(\s*and\s)?\Z/, '').strip, fn]
    else
      nil
    end
  end

end
end