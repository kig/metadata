require 'uri'
require 'hpricot'
require 'yaml'
require 'open-uri'
require 'metadata/bibtex'
require 'cgi'

class DBLP

  def self.get_info(title)
    url = "http://www.informatik.uni-trier.de/ley/dbbin/dblpquery.cgi?title=#{CGI.escape title.gsub(/[^a-zA-Z0-9]/,' ').strip}"
    dblp_search_data = begin
      open(url){|f| f.read }
    rescue => e
      STDERR.puts e, e.backtrace
      return {}
    end

    dblp_id = dblp_search_data.scan(/\[DBLP:([^\]]+)\]/).flatten.first

    return {} unless dblp_id

    data_url = "http://dblp.uni-trier.de/rec/bibtex/#{dblp_id}"
    begin
      data = open(data_url){|f| f.read }
      page = Hpricot.parse(data)
      bibtex = (page / 'pre').first.inner_text
      BibTex.parse(bibtex)
    rescue => e
      STDERR.puts e, e.backtrace
      {}
    end
  end

end

