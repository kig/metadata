require 'uri'
require 'cgi'
require 'hpricot'
require 'yaml'
require 'open-uri'
require 'text'
require 'lib/metadata/bibtex'

class String
  def rsplit(*args)
    reverse.split(*args).map{|h| h.reverse! }.reverse!
  end
end

class CiteSeer

  def self.get_info(title)
    title = title.to_utf8
    url = "http://citeseer.ist.psu.edu/cs?Documents&af=Title&q=#{CGI.escape title}"
    page = begin
      Hpricot.parse(open(url){|f| f.read })
    rescue => e
      STDERR.puts e, e.backtrace
      return {}
    end

    links = (page/'a').find_all{|a|
      a[:href] =~ %r{^http://citeseer.ist.psu.edu/([^/]+\.html)$}
    }

    if links.empty?
      return {}
    end

    sorted_links = links.sort_by{|a|
      Text::Levenshtein.distance(title.downcase, a.inner_text.rsplit(" - ",2).first.downcase.to_utf8)
    }
    link = sorted_links.first

    if Text::Levenshtein.distance(title.downcase, link.inner_text.rsplit(" - ",2).first.downcase.to_utf8) > (title.length / 2)
      return {}
    end


    data_url = link[:href]
    data = open(data_url){|f| f.read }
    bibtex = data.scan(/<pre>(.*)<\/pre>/im).flatten.first
    bibtex_hash = BibTex.parse(bibtex)

    abstract = ""
    citations = []
    abstract = data.split(/Abstract:<\/b>\s*/,2)[1].split("<a ",2)[0] rescue ""

    begin
      citation_html = data.split("Citations (may not include all citations):", 2)[1].
                          split("Documents on the same site",2)[0]
      citations = citation_html.split("<br>").inject([]){|s,i|
        s += i.scan(%r{(http://citeseer.ist.psu.edu/(context/\d+/\d+|[^/]+\.html))">([^<]+)<[^>]*>(\s*-\s*)?([^\n]+)}).
              map{|href,_,text,_,rest|
                {
                'href' => href,
                'title' => text,
                'rest' => rest.gsub(/"\/(ACM|DBLP)LINK\//,'"')
                }
              }
      }
    rescue => e
    end

    oai_hash = {}
    begin
      doc_id = data.scan(%r{http://citeseer.ist.psu.edu/correct/(\d+)}).flatten.first
      oai_url = "http://cs1.ist.psu.edu/cgi-bin/oai.cgi?verb=GetRecord&metadataPrefix=oai_dc&identifier=oai%3ACiteSeerPSU%3A#{doc_id}"
      oai_data = open(oai_url){|f| f.read }
      oai = Hpricot.parse(oai_data)
      metadata = oai / 'metadata'
      oai = Hpricot.parse(oai_data)
      metadata = oai / 'metadata'
      %w(title subject creator description contributor publisher date source language identifier).each{|field|
        value = (metadata / "dc:#{field}").innerHTML
        oai_hash[field] = value unless value.empty?
      }
    rescue => e
      STDERR.puts e, e.backtrace
    end

    md_hash = {
      'description' => abstract,
      'citations' => citations
    }
    merged_hash = md_hash.merge(bibtex_hash).merge(oai_hash)

    if merged_hash['date'] and merged_hash['year'] and merged_hash['date'][0,4] != merged_hash['year']
      merged_hash.delete('date')
    end

    merged_hash
  end

end

