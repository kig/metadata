class BibTex

  def self.parse(bibtex)
    type_and_id, bibtex_body = bibtex.strip.sub(/\}\s*\Z/m,'').split(",",2)
    bib_type, bib_id = type_and_id.split("{",2)
    bibtex_hash = parse_kv_pairs(bibtex_body)
    
    bibtex_hash['bibtex_type'] = bib_type[1..-1]
    bibtex_hash['bibtex_id'] = bib_id
    bibtex_hash
  end

  def self.parse_kv_pairs(str)
    h = {}
    until str.strip.empty?
      k,v,str = parse_kv_pair(str)
      h[k] = v
    end
    h
  end

  def self.parse_kv_pair(str)
    key = str[/^[^=]+/m]
    rest = str[key.length+1..-1]
    key.strip!
    esc_begin = rest[/^\s*./m]
    rest = rest[esc_begin.length..-1]
    esc_begin.strip!
    case esc_begin
    when "{"
      close = '}'
    when '"'
      close = '"'
    end
    value = rest[/[^#{"\\"+close}]*/]
    rest = rest[value.length+1..-1].sub(/\A\s*,\s*/m,'')
    [key, value.gsub(/\n\s*/m,' '), rest]
  end
  
end

# BIBTEX ::= BIBTEX_TYPE BIBTEX_BODY
# BIBTEX_TYPE ::= /^@[a-z]+/
# BIBTEX_BODY ::= '{' BIBTEX_ID ',' COMMA_SEPARATED_LIST '}'
# BIBTEX_ID ::= /[^,]+/
# COMMA_SEPARATED_LIST ::= LIST_ENTRY ( e | ',' COMMA_SEPARATED_LIST )
# LIST_ENTRY ::= STRING '=' VALUE
# VALUE ::= '"' STRING '"' | '{' STRING '}'