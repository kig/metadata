# coding: utf-8
require 'rubygems'
require 'rchardet19'
require 'iconv'
require 'pathname'
require 'time'
require 'date'
require 'base64'

require 'metadata/mime_info'



class Pathname

  attr_accessor 'mimetype'

  def mimetype
    @mimetype ||= MimeInfo.get(to_s)
  end

  def pages
    @pages ||= (metadata['Doc.PageCount'] || 1)
  end

  def dimensions
    @dimensions ||= [width, height]
  end

  def metadata(mime=mimetype, pdf=nil)
    @metadata ||= Metadata.extract(self, mime || mimetype, pdf)
  end

  def length
    @length ||= (metadata['Audio.Duration'] || metadata['Video.Duration'] || metadata['Doc.WordCount'].to_i / 250.0)
  end

  def width
    metadata['Image.Width']
  end

  def height
    metadata['Image.Height']
  end
end

class Array

  def to_hash
    h = {}
    each{|k,v| h[k] = v}
    h
  end

end

class Numeric

  def points_to_mm
    self * 0.3528
  end

  def mm_to_points
    self / 0.3528
  end

end

module Metadata
extend self

# @param [String] string
  def self.to_utf8(string)
    #string.unpack('C*').pack('U*') # does not work correctly
    cd = ::CharDet.detect(string, :silent => true)
    # TODO use logger
    STDERR.puts "Encoding #{cd.encoding} whis confidence #{cd.confidence}" if verbose
    if cd.confidence > 0.6 then
      string.encode('utf-8', cd.encoding, :invalid => :replace)
      #Iconv.conv("UTF-8", cd.encoding, string)
    else
      ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
      ic.iconv(string + ' ')[0..-2]
    end

  end

  attr_accessor(:quiet, :verbose,
                :sha1sum, :md5sum,
                :no_text, :guess_title, :guess_metadata, :guess_pubdata,
                :use_citeseer, :use_dblp,
                :include_name, :include_path)

  # Extracts metadata from a file by guessing mimetype and calling matching
  # extractor methods (which mostly call external programs to do their bidding.)
  #
  #   Metadata.extract('foo.png')
  #
  # Follows the Shared File Metadata Spec naming.
  # http://wiki.freedesktop.org/wiki/Specifications/shared-filemetadata-spec
  #
  # There are a couple flags that control the behaviour of
  # the metadata extractor:
  #
  #   Metadata.sha1sum = true # include File.SHA1Sum in the metadata
  #   Metadata.md5sum = true  # include File.MD5Sum in the metadata
  #   Metadata.include_name = true # include File.Name (file basename)
  #   Metadata.include_path = true # include File.Path (file dirname)
  #   Metadata.quiet = true   # override verbose to false
  #   Metadata.verbose = true # print out status messages to stderr
  #
  # All strings are converted to UTF-8.
  #
  def extract(filename, mimetype=MimeInfo.get(filename.to_s), pdf=nil)
    verbose = self.verbose && !self.quiet
    filename = filename.to_s
    mimetype = Mimetype[mimetype] unless mimetype.is_a?( Mimetype )
    unless File.exist?(filename)
      rv = {}
      if self.include_name
        rv['File.Name'] = File.basename(filename)
      end
      if self.include_path
        rv['File.Path'] = File.dirname(filename)
      end
      rv['File.Format'] ||= mimetype.to_s
      return rv
    end
    mts = mimetype.ancestors
    mt = mts.shift
    rv = nil
    new_methods = public_methods(false)
    STDERR.puts "Processing #{filename}", " Metadata extraction" if verbose
    while mt.is_a?(Mimetype) and mt != Mimetype
      STDERR.puts "  Trying #{mt}" if verbose
      mn = mt.to_s.gsub(/[^a-z0-9]/i,"_").to_sym
      if new_methods.include?( mn )
        begin
          rv = __send__( mn, filename )
          STDERR.puts "  OK" if verbose
          break
        rescue => e
          STDERR.puts(e, e.message, e.backtrace) if verbose
        end
      end
      mt = mts.shift
    end
    unless rv
      STDERR.puts "  Falling back to extract" if verbose
      rv = extract_extract_info(filename)
    end
    if self.include_name
      rv['File.Name'] = File.basename(filename)
    end
    if self.include_path
      rv['File.Path'] = File.dirname(filename)
    end
    rv['File.Format'] ||= mimetype.to_s
    if File.file?(filename)
      if self.sha1sum
        secure_filename(filename){|sfn|
          rv['File.SHA1Sum'] = `sha1sum #{sfn}`.split(" ",2)[0]
        }
      end
      if self.md5sum
        secure_filename(filename){|sfn|
          rv['File.MD5Sum'] = `md5sum #{sfn}`.split(" ",2)[0]
        }
      end
    end
    rv['File.Size'] = (
      if File.directory?(filename)
        Dir.entries(filename).size-2
      else
        File.size(filename)
      end)
    rv['File.Content'] = extract_text(filename, mimetype, false) unless Metadata.no_text
    pdf ||= filename + "-temp.pdf"
    if File.exist?(pdf)
      pdf_metadata = application_pdf(pdf)
      overrides = %w(Image.DimensionUnit Image.Width Image.Height Doc.PageCount
                     Doc.PageSizeName)
      optrides = %w(Doc.WordCount Doc.Title Doc.Author)
      overrides.each{|o| rv[o] = pdf_metadata[o] }
      optrides.each {|o| rv[o] ||= pdf_metadata[o] }
      if !Metadata.no_text and not to_s =~ /postscript/
        rv['File.Content'] = extract_text(pdf, Mimetype['application/pdf'], false)
      end
    end
    if guess_title or guess_metadata or guess_pubdata
      gem_require 'metadata/title_guesser'
      gem_require 'metadata/publication_guesser'
      gem_require 'metadata/reference_guesser'
      text = (rv['File.Content'] || extract_text(filename, mimetype, false))
      guess = extract_guesses(text)
      if guess['Doc.Title'] and (rv['Doc.Title'].nil? or rv['Doc.Title'] =~ /(^[a-z])|((\.(dvi|doc)|WORD)$)|^Slide 1$|^PowerPoint Presentation$/)
        rv['Doc.Title'] = guess['Doc.Title']
      end
    end
    if use_citeseer and rv['Doc.Title'] and mimetype.to_s =~ /pdf|postscript|dvi|tex/
      rv.merge!(citeseer_extract(rv['Doc.Title']))
    end
    if use_dblp and rv['Doc.Title'] and mimetype.to_s =~ /pdf|postscript|dvi|tex/
      rv.merge!(dblp_extract(rv['Doc.Title']))
    end
    if guess_metadata or guess_pubdata
      %w(Doc.Publisher Doc.Published Doc.Publication Doc.Genre Event.Name Event.Organizer
      ).each{|field|
        rv[field] ||= guess[field] if guess[field]
      }
    end
    if guess_metadata
      %w(Doc.Citations Doc.Description Doc.ACMCategories Doc.Keywords
      ).each{|field|
        rv[field] ||= guess[field] if guess[field]
      }
    end
    rv['File.Modified'] = File.mtime(filename.to_s)
    rv.delete_if{|k,v| v.nil? }

    rv.dup.each do |key, value|
      rv[key] = if value.is_a? String and !value.frozen? then Metadata.to_utf8(value) else value end
    end

    rv
  end

  # Extracts text from a file by guessing mimetype and calling matching
  # extractor methods (which mostly call external programs to do their bidding.)
  #
  # The extracted text is converted to UTF-8.
  #
  def extract_text(filename, mimetype=MimeInfo.get(filename.to_s), layout=false)
    filename = filename.to_s
    mimetype = Mimetype[mimetype] unless mimetype.is_a?( Mimetype )
    mts = mimetype.ancestors
    mt = mts.shift
    new_methods = public_methods(false)
    STDERR.puts " Text extraction" if verbose
    while mt.is_a?(Mimetype) and mt != Mimetype
      STDERR.puts "  Trying #{mt}" if verbose
      mn = (mt.to_s.gsub(/[^a-z0-9]/i,"_") + "__gettext").to_sym
      if new_methods.include?( mn )
        begin
          rv = __send__( mn, filename, layout )
          STDERR.puts "  OK" if verbose
          return rv
        rescue => e
          STDERR.puts(e, e.message, e.backtrace) unless quiet
        end
      end
      mt = mts.shift
    end
    STDERR.puts "  Text extraction failed" if verbose
    nil
  end

  alias_method :[], 'extract'

  def gem_require(libname)
    retried = false
    begin
      require libname
    rescue LoadError
      unless retried
        STDERR.puts "Requiring rubygems" if verbose
        require 'rubygems'
        retried = true
        retry
      else
        raise
      end
    end
  end

  def extract_guesses(text)
    return {} unless text
    guess = {}

    title = TitleGuesser.guess_title(text)
    pubdata = PublicationGuesser.guess_pubdata(text)

    str = remove_ligatures(text).split(/\f+/m)[0,2].join("\n")
    abstract = str.scan(
      /\babstract\s*\n(.+)\n\s*((d+\.)|(\d\.?)*\s*(keywords|categories|introduction|(\d\.?)\s*[a-z]+))\s*\n/im
    ).flatten.first

    if abstract
      abstract.gsub!(/\A(\s*[a-z]+@([a-z]+\.)+[a-z]+\s*)+/im, '')
      if abstract.size > 500
        abstract = abstract.split(/(?=\n)/).inject(""){|s,i|
          s << i unless s.size > 500
          s
        }
      end
    end

    kw_re = /\bkeywords:?\b/i
    cat_re = /\bcategories:?\b/i
    acm_cat_re = /\b([A-K]\.(\d(\.\d)?)?)\b/
    kw_list_re = /(([^\.]+,)+[^\.\n]+)/m
    if str =~ cat_re
      cats = str.split(cat_re,2).last.
                      scan(acm_cat_re).
                      map{|hit| hit[0] }
    end
    if str =~ kw_re
      kws = str.split(kw_re)[1..-1].map{|kw|
                      kw.scan(kw_list_re).flatten.first
                    }.compact.
                    map{|hit| hit.split(/\s*,\s*/).map{|s|s.strip} }.
                    max{|a,b| a.length <=> b.length }
    end

#     cites = ReferenceGuesser.guess_references(text)

    guess['Doc.Title'] = title.strip if title and title.strip.size < 100
    guess['Doc.Description'] = abstract.strip if abstract
#     guess['Doc.Citations'] = cites if cites and not cites.empty?
    guess['Doc.Keywords'] = kws if kws and not kws.empty?
    if cats and not cats.empty?
      require 'metadata/acm_categories'
      guess['Doc.ACMCategories'] = cats.map{|cat|
        "#{cat.upcase} #{ACM_CATEGORIES[cat.upcase]}"
      }
    end
    guess = guess.merge(pubdata)
    guess
  end


  def audio_x_flac(fn)
    gem_require 'flacinfo'
    m = nil
    begin
      m = FlacInfo.new(fn)
    rescue # FlacInfo fails for flacs with id3 tags
      return audio(fn)
    end
    t = m.tags
    si = m.streaminfo
    len = si["total_samples"].to_f / si["samplerate"]
    md = {
      'Audio.Codec' => 'FLAC',
      'Audio.Title' => t['TITLE'],
      'Audio.Artist' => t['ARTIST'],
      'Audio.Album' => t['ALBUM'],
      'Audio.Comment' => t['COMMENT'],
      'Audio.Bitrate' => File.size(fn)*8 / len,
      'Audio.Duration' => len,
      'Audio.Samplerate' => si["samplerate"],
      'Audio.VariableBitrate' => true,
      'Audio.Genre' => parse_genre(t['GENRE']),
      'Audio.ReleaseDate' => parse_time(t['DATE']),
      'Audio.TrackNo' => parse_num(t['TRACKNUMBER'], :i),
      'Audio.Channels' => si["channels"]
    }
    ad = (audio(fn) rescue {})
    ad.delete_if{|k,v| v.nil? }
    md.merge(ad)
  end

  def audio_mp4(fn)
    gem_require 'mp4info'
    m = MP4Info.open(fn)
    tn, total = m.TRKN
    md = {
      'Audio.Title' => m.NAM,
      'Audio.Artist' => m.ART,
      'Audio.Album' => m.ALB,
      'Audio.Bitrate' => m.BITRATE,
      'Audio.Duration' => m.SECS,
      'Audio.Samplerate' => m.FREQUENCY*1000,
      'Audio.VariableBitrate' => true,
      'Audio.Genre' => parse_genre(m.GNRE),
      'Audio.ReleaseDate' => parse_time(m.DAY),
      'Audio.TrackNo' => parse_num(tn, :i),
      'Audio.AlbumTrackCount' => parse_num(total, :i),
      'Audio.Writer' => m.WRT,
      'Audio.Copyright' => m.CPRT,
      'Audio.Tempo' => parse_num(m.TMPO, :i),
      'Audio.Codec' => m.ENCODING,
      'Audio.AppleID' => m.APID,
      'Audio.Image' => base64(m.COVR),
    }
  end

  def audio_x_ms_wma(fn)
    gem_require 'wmainfo'
    # hack hack hacky workaround
    m = WmaInfo.allocate
    m.instance_variable_set("@ext_info", {})
    m.__send__(:initialize, fn)
    t = m.tags
    si = m.info
    md = {
      'Audio.Codec' => 'Windows Media Audio',
      'Audio.Title' => t['Title'],
      'Audio.Artist' => t['Author'],
      'Audio.Album' => t['AlbumTitle'],
      'Audio.AlbumArtist' => t['AlbumArtist'],
      'Audio.Bitrate' => si["bitrate"],
      'Audio.Duration' => si["playtime_seconds"],
      'Audio.Genre' => parse_genre(t['Genre']),
      'Audio.ReleaseDate' => parse_time(t['Year']),
      'Audio.TrackNo' => parse_num(t['TrackNumber'], :i),
      'Audio.Copyright' => t['Copyright'],
      'Audio.VariableBitrate' => (si['IsVBR'] == 1)
    }
  end

  def audio_x_ape(fn)
    gem_require 'apetag'
    m = ApeTag.new(fn)
    t = m.fields
    ad = (id3lib_extract(fn) rescue {})
    fields = %w(Title Artist Album Comment Genre Subtitle Publisher Conductor
       Composer Copyright Publicationright File EAN/UPC ISBN Catalog
       LC Media Index Related ISRC Abstract Language Bibliography
       Introplay Dummy) + ['Debut Album', 'Record Date', 'Record Location']
    md = {
      'Audio.ReleaseDate' => parse_time(t['Year']),
      'Audio.TrackNo' => parse_num(t['Track'], :i)
    }
    fields.each{|k| md["Audio.#{k.gsub(" ", "")}"] = t[k] }
    ad.delete_if{|k,v| v.nil? }
    md['Audio.Genre'] = parse_genre(md['Audio.Genre'])
    md.merge(ad)
  end
  alias_method :audio_x_musepack, :audio_x_ape
  alias_method :audio_x_wavepack, :audio_x_ape

  def audio_mpeg(fn)
    gem_require 'mp3info'
    h = audio(fn)
    begin
      Mp3Info.open(fn){|mp3|
        h['Audio.Duration'] = mp3.length
        h['Audio.Bitrate'] = mp3.bitrate
        h['Audio.VariableBitrate'] = mp3.vbr
      }
    rescue => e
    end
    h
  end

  def application_pdf(filename)
    h = pdfinfo_extract_info(filename)
    secure_filename(filename){|tfn|
      h['words'] = `pdftotext #{tfn} - | wc -w 2>/dev/null`.strip.to_i
    }
    if h['keywords']
      keywords = h['keywords'].split(/[,.]/).map{|s| s.strip }.find_all{|s| not s.empty? }
    end
    md = {
      'Doc.Title' => h['title'],
      'Doc.Author' => h['author'],
      'Doc.Created' => parse_time(h['creationdate']),
      'Doc.Subject' => h['subject'],
      'Doc.Modified' => parse_time(h['moddate']),
      'Doc.PageCount' => h['pages'],
      'Doc.Keywords' => keywords,
      'Doc.PageSizeName' => h['page_size'],
      'Doc.WordCount' => h['words'],
      'Image.Width' => parse_num(h['width'], :f),
      'Image.Height' => parse_num(h['height'], :f),
      'Image.DimensionUnit' => 'mm'
    }
    md.delete_if{|k,v| v.nil? }
    md
  end

  def application_postscript(filename)
    extract_extract_info(filename)
  end
  alias_method :application_x_gzpostscript, :application_postscript

  def text_html(filename)
    gem_require 'hpricot'
    words = secure_filename(filename){|tfn|
      `lynx -dump -display_charset=UTF-8 -nolist #{tfn} | wc -w 2>/dev/null`
    }.strip.to_i
    html = (File.read(filename, 65536) || "")
    h = {
      'Doc.WordCount' => words
    }
    begin
      page = Hpricot.parse(html)
      te = (page / 'title')[0]
      if te
        title = te.inner_text
        h['Doc.Title'] = title
      end
      tagstr = __get_meta(page, 'keywords')
      if tagstr
        h['Doc.Keywords'] = tagstr.split(/\s*,\s*/)
      end
      h['Doc.Description'] = __get_meta(page, 'description')
      h['Doc.Author'] = (__get_meta(page, 'author') ||
                         __get_meta(page, 'dc.author'))
      h['Doc.Publisher'] = (__get_meta(page, 'publisher') ||
                         __get_meta(page, 'dc.publisher'))
      h['Doc.Subject'] = (__get_meta(page, 'subject') ||
                         __get_meta(page, 'dc.subject'))
      geopos = __get_meta(page, 'geo.position')
      icbm = __get_meta(page, 'icbm')
      if geopos
        latlon = geopos.strip.split(/\s*;\s*/).map{|n| n.to_f }
      elsif icbm
        latlon = icbm.strip.split(/\s*,\s*/).map{|n| n.to_f }
      end
      if latlon and latlon.size == 2
        h['Location.Latitude'] = latlon[0]
        h['Location.Longitude'] = latlon[1]
      end
    rescue
    end
    h
  end

  def __get_meta(page, name)
    tag = (page / 'meta').find{|e|
            e['name'].to_s.downcase == name.downcase }
    return tag['content'].to_s if tag
    nil
  end

  def text(filename)
    words = secure_filename(filename){|tfn| `wc -w #{tfn} 2>/dev/null` }.strip.to_i
    {
      'Doc.WordCount' => words,
    }
  end

# TODO sometimes calls twise
  def audio(filename)
    id3 = (id3lib_extract(filename) rescue {})
    h = mplayer_extract_info(filename)
    info = {
      'Audio.Duration' => (h['length'].to_i > 0) ? parse_num(h['length'], :f) : nil,
      'Audio.Bitrate' => h['audio_bitrate'] && h['audio_bitrate'] != '0' ?
                       parse_num(h['audio_bitrate'], :i) / 1000.0 : nil,
      'Audio.Codec' => h['audio_format'],
      'Audio.Samplerate' => parse_num(h['audio_rate'], :i),
      'Audio.Channels' => parse_num(h['audio_nch'], :i),

      'Audio.Title' => h['title'] || h['name'],
      'Audio.Artist' => h['artist'] || h['author'],
      'Audio.Album' => h['album'],
      'Audio.ReleaseDate' => parse_time(h['date'] || h['creation date'] || h['year']),
      'Audio.Comment' => h['comment'] || h['comments'],
      'Audio.TrackNo' => parse_num(h['track'], :i),
      'Audio.Copyright' => h['copyright'],
      'Audio.Software' => h['software'],
      'Audio.Genre' => parse_genre(h['genre'])
    }
    id3.delete_if{|k,v| v.nil? }
    info.merge(id3)
  end

  def video(filename)
    id3 = (id3lib_extract(filename) rescue {})
    h = mplayer_extract_info(filename)
    info = {
      'Image.Width' => parse_num(h['video_width'], :f),
      'Image.Height' => parse_num(h['video_height'], :f),
      'Image.DimensionUnit' => 'px',
      'Video.Duration' => (h['length'].to_i > 0) ? parse_num(h['length'], :f) : nil,
      'Video.Framerate' => parse_num(h['video_fps'], :f),
      'Video.Bitrate' => h['video_bitrate'] && h['video_bitrate'] != '0' ?
                       parse_num(h['video_bitrate'], :i) / 1000.0 : nil,
      'Video.Codec' => h['video_format'],
      'Audio.Bitrate' => h['audio_bitrate'] && h['audio_bitrate'] != '0' ?
                       parse_num(h['audio_bitrate'], :i) / 1000.0 : nil,
      'Audio.Codec' => h['audio_format'],
      'Audio.Samplerate' => parse_num(h['audio_rate'], :i),
      'Audio.Channels' => parse_num(h['audio_nch'], :i),

      'Video.Title' => h['title'] || h['name'],
      'Video.Artist' => h['artist'] || h['author'],
      'Video.Album' => h['album'],
      'Video.ReleaseDate' => parse_time(h['date'] || h['creation date'] || h['year']),
      'Video.Comment' => h['comment'] || h['comments'],
      'Video.TrackNo' => parse_num(h['track'], :i),
      'Video.Genre' => parse_genre(h['genre']),
      'Video.Copyright' => h['copyright'],
      'Video.Software' => h['software'],
      'Video.Demuxer' => h['demuxer']
    }
    case h['demuxer']
    when 'avi'
      info['File.Format'] = 'video/x-msvideo'
    when 'mkv'
      info['File.Format'] = 'video/x-matroska'
    when 'mov'
      info['File.Format'] = 'video/quicktime'
    end
    id3.delete_if{|k,v| v.nil? }
    info.merge(id3)
  end
  alias_method('application_x_flash_video', 'video')

  def video_x_ms_wmv(filename)
    h = video(filename)
    wma = audio_x_ms_wma(filename)
    %w(
      Bitrate Artist Title Album Genre ReleaseDate TrackNo VariableBitrate
    ).each{|t|
      h['Video.'+t] = wma['Audio.'+t]
    }
    %w(Samplerate Codec).each{|t|
      h['Audio.'+t] = wma['Audio.'+t]
    }
    h
  end
  alias_method('video_x_ms_asf', 'video_x_ms_wmv')

  def image(filename)
    #begin
    #  gem_require 'imlib2'
    #  img = Imlib2::Image.load(filename.to_s)
    #  w = img.width
    #  h = img.height
    #  id_out = ""
    #  img.delete!
    #rescue Exception
      id_out = secure_filename(filename){|tfn| `identify #{tfn}` }
      w,h = id_out.scan(/[0-9]+x[0-9]+/)[0].split("x",2)
    #end
    exif = (extract_exif(filename) rescue {})
    info = {
      'Image.Width' => parse_num(w, :f),
      'Image.Height' => parse_num(h, :f),
      'Image.DimensionUnit' => 'px',
      'Image.LayerCount' => [id_out.split("\n").size, 1].max
    }.merge(exif)
    info
  end

  def image_svg_xml(filename)
    id_out = secure_filename(filename){|tfn| `identify #{tfn}` }
    w,h = id_out.scan(/[0-9]+x[0-9]+/)[0].split("x",2)
    info = {
      'Image.Width' => parse_num(w, :f),
      'Image.Height' => parse_num(h, :f),
      'Image.DimensionUnit' => 'px'
    }
    info
  end

  def image_gif(filename)
    id_out = secure_filename(filename){|tfn| `identify #{tfn}` }
    w,h = id_out.scan(/[0-9]+x[0-9]+/)[0].split("x",2)
    exif = (extract_exif(filename) rescue {})
    info = {
      'Image.Width' => parse_num(w, :f),
      'Image.Height' => parse_num(h, :f),
      'Image.DimensionUnit' => 'px',
      'Image.FrameCount' => [id_out.split("\n").size, 1].max
    }.merge(exif)
    info
  end

  def image_x_dcraw(filename)
    exif = (extract_exif(filename) rescue {})
    dcraw = extract_dcraw(filename)
    info = {
      'Image.Frames' => 1,
      'Image.DimensionUnit' => 'px'
    }.merge(exif).merge(dcraw)
    info
  end

  def application_x_bittorrent(fn)
    require 'metadata/bt'
    h = File.read(fn).bdecode
    i = h['info']
    name = i['name.utf-8'] || i['name']
    {
      'Doc.Title' => name,
      'BitTorrent.Name' => name,
      'BitTorrent.Files' =>
        if i['files']
          i['files'].map{|f|
            up = f['path.utf-8']
            up = up.join("/") if up.is_a?(Array)
            pt = f['path']
            pt = pt.join("/") if pt.is_a?(Array)
            fh = {"path" => (up || pt),
             "length" => f['length']
            }
            fh['md5sum'] = f['md5sum'] if f['md5sum']
            fh
          }
        else
          nil
        end,
      'BitTorrent.Length' => i['length'],
      'BitTorrent.MD5Sum' => i['md5sum'],
      'BitTorrent.PieceLength' => i['piece length'],
      'BitTorrent.PieceCount' => i['pieces'].size / 20,

      'File.Software' => h['created by'],
      'Doc.Created' => parse_time(Time.at(h['creation date']).iso8601),
      'BitTorrent.Comment' => h['comment'],
      'BitTorrent.Announce' => h['announce'],
      'BitTorrent.AnnounceList' => h['announce-list'],
      'BitTorrent.Nodes' => h['nodes']
    }
  end


  def text__gettext(filename, layout=false)
    (File.read(filename) || "")
  end

  def text_html__gettext(filename, layout=false)
    secure_filename(filename){|tfn| `lynx -dump -display_charset=UTF-8 -nolist #{tfn}` }
  end

  def application_pdf__gettext(filename, layout=false)
    page = 0
    str = secure_filename(filename){|tfn| `pdftotext #{layout ? "-layout " : ""}-enc UTF-8 #{tfn} -` }
    if layout
      str.gsub!(/\f/u, "\f\n")
      str.gsub!(/^/u, " ")
      str.gsub!(/\A| ?\f/u) {|pg|
        "\nPage #{page+=1}.\n"
      }
      str.sub!(/\n+/, "")
      str.sub!(/1\./, "1.\n")
    end
    str
  end

  def application_postscript__gettext(filename, layout=false)
    page = 0
    str = secure_filename(filename){|tfn| `pstotext #{tfn}` }
    if layout
      str.gsub!(/\f/u, "\f\n")
      str.gsub!(/^/u, " ")
      str.gsub!(/\A| ?\f/u) {|pg|
        "\nPage #{page+=1}.\n"
      }
      str.sub!(/\n+/, "")
      str.sub!(/1\./, "1.\n")
    end
    str # pstotext outputs iso-8859-1
  end

  def application_x_gzpostscript__gettext(filename, layout=false)
    page = 0
    str = secure_filename(filename){|tfn| `zcat #{tfn} | pstotext -` }
    if layout
      str.gsub!(/\f/u, "\f\n")
      str.gsub!(/^/u, " ")
      str.gsub!(/\A| ?\f/u) {|pg|
        "\nPage #{page+=1}.\n"
      }
      str.sub!(/\n+/, "")
      str.sub!(/1\./, "1.\n")
    end
    str # pstotext outputs iso-8859-1
  end

  def application_msword__gettext(filename, layout=false)
    secure_filename(filename){|sfn| `antiword #{sfn}` }
  end

  def application_rtf__gettext(filename, layout=false)
    secure_filename(filename){|sfn| `catdoc -d UTF-8 #{sfn}` }
  end

  def application_vnd_ms_powerpoint__gettext(filename, layout=false)
    secure_filename(filename){|sfn| `catppt -d UTF-8 #{sfn}` }
  end

  def application_vnd_ms_excel__gettext(filename, layout=false)
    secure_filename(filename){|sfn| `xls2csv -d UTF-8 #{sfn}` }
  end



  OPEN_OFFICE_TYPES = %w(
  application/vnd.oasis.opendocument.text
  application/vnd.oasis.opendocument.text-template
  application/vnd.oasis.opendocument.text-web
  application/vnd.oasis.opendocument.text-master
  application/vnd.oasis.opendocument.graphics
  application/vnd.oasis.opendocument.graphics-template
  application/vnd.oasis.opendocument.presentation
  application/vnd.oasis.opendocument.presentation-template
  application/vnd.oasis.opendocument.spreadsheet
  application/vnd.oasis.opendocument.spreadsheet-template
  application/vnd.oasis.opendocument.presentation
  application/vnd.oasis.opendocument.chart
  application/vnd.oasis.opendocument.formula
  application/vnd.oasis.opendocument.database

  application/vnd.sun.xml.writer
  application/vnd.sun.xml.writer.template
  application/vnd.sun.xml.calc
  application/vnd.sun.xml.calc.template
  application/vnd.sun.xml.impress
  application/vnd.sun.xml.impress.template
  application/vnd.sun.xml.writer.global
  application/vnd.sun.xml.math

  application/vnd.stardivision.writer
  application/vnd.stardivision.writer-global
  application/vnd.stardivision.calc
  application/vnd.stardivision.impress
  application/vnd.stardivision.impress-packed
  application/vnd.stardivision.math
  application/vnd.stardivision.chart
  application/vnd.stardivision.mail

  application/x-starwriter
  application/x-starcalc
  application/x-stardraw
  application/x-starimpress
  application/x-starmath
  application/x-starchart)

  OFFICE_TYPES = %w(
  application/msword
  application/rtf
  application/vnd.openxmlformats-officedocument.presentationml.presentation
  application/vnd.openxmlformats-officedocument.wordprocessingml.document
  application/vnd.ms-word.document.macroenabled.12
  application/vnd.openxmlformats-officedocument.wordprocessingml.template
  application/vnd.ms-word.template.macroenabled.12
  application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  application/vnd.ms-excel.sheet.macroenabled.12
  application/vnd.openxmlformats-officedocument.spreadsheetml.template
  application/vnd.ms-excel.template.macroenabled.12
  application/vnd.openxmlformats-officedocument.presentationml.presentation
  application/vnd.ms-powerpoint.presentation.macroenabled.12
  application/vnd.openxmlformats-officedocument.presentationml.template
  application/vnd.ms-powerpoint.template.macroenabled.12
  application/vnd.ms-excel.sheet.binary.macroenabled.12
  application/vnd.ms-word
  application/vnd.ms-excel
  application/vnd.ms-powerpoint
  )

  def self.create_text_extractor(mimetype, &block)
    major,minor = mimetype.to_s.gsub(/[^\/a-z0-9]/i,"_").split("/")
    mn = [major,minor,"_gettext"].join("_")
    define_method(mn, &block)
  end

  def self.create_info_extractor(mimetype, &block)
    major,minor = mimetype.to_s.gsub(/[^\/a-z0-9]/i,"_").split("/")
    mn = [major,minor].join("_")
    define_method(mn, &block)
  end

  (OPEN_OFFICE_TYPES).each{|t|
    create_text_extractor(t) do |filename, layout|
      nil
    end
  }

  (OPEN_OFFICE_TYPES + OFFICE_TYPES).each{|t|
    create_info_extractor(t) do |filename|
      extract_extract_info(filename)
    end
  }

  def mplayer_extract_info(filename)
    mplayer = `which mplayer32 2>/dev/null`.strip
    mplayer = `which mplayer 2>/dev/null`.strip if mplayer.empty?
    mplayer = "mplayer" if mplayer.empty?
    output = IO.popen("#{mplayer.dump} -quiet -identify -vo null -ao null -frames 0 -playlist - 2>/dev/null", "r+"){|mp|
      mp.puts filename
      mp.close_write
      mp.read
    }
    ids = output.split("\n").grep(/^ID_/).map{|t|
      k,v, = t.split("=",2)
      k = k.downcase[3..-1]
      [k,v]
    }
    hash = Hash[*ids.flatten]
    hash.dup.each{|k,v|
      if k =~ /^clip_info_name/
        hash[v.downcase] = hash[k.sub("name", "value")]
      end
    }
    f = {
      '85' => 'MP3',
      'fLaC' => 'FLAC',
      'vrbs' => 'Vorbis',
      'hwac3' => 'AC3',
      '1' => 'PCM',
      '7' => 'Sun Audio',
      '353' => 'Windows Media Audio'
    }
    hash['audio_format'] = f[hash['audio_format']] if f[hash['audio_format']]
    hash
  end

  def extract_extract_info(filename)
    arr = secure_filename(filename){|tfn| `extract #{tfn}` }.strip.split("\n").map{|s| s.split(" - ",2) }
    h = arr.to_hash
    filenames = arr.keep_if{|k,v| k == 'filename' }.map{|k,v| v}
    keywords  = arr.keep_if{|k,v| k == 'keywords' }.map{|k,v| v}
    revisions = arr.keep_if{|k,v| k == 'revision history' }.map{|k,v| v}
    md = {
      'Doc.Title' => h['title'],
      'Doc.Subject' => h['subject'],
      'Doc.Author' => h['creator'],
      'Doc.LastSavedBy' => h['last saved by'],

      'Doc.Language' => h['language'],

      'Doc.Artist' => h['artist'],
      'Doc.Genre' => h['genre'],
      'Doc.Album' => h['album'],
      'Doc.Language' => h['language'],

      'Doc.Created' => parse_time(h['creation date']),
      'Doc.Modified' => parse_time(h['modification date'] || h['date']),
      'Doc.RevisionHistory' => revisions.empty? ? nil : revisions,

      'Doc.Description' => h['description'],
      'Doc.Keywords' => keywords.empty? ? nil : keywords,

      'File.Software' => h['software'] || h['generator'],
      'Doc.Template' => h['template'],

      'Archive.Contents' => filenames.empty? ? nil : filenames,

      'Doc.WordCount' =>      parse_num(h['word count'], :i),
      'Doc.PageCount' =>      parse_num(h['page count'], :i),
      'Doc.ParagraphCount' => parse_num(h['paragraph count'], :i),
      'Doc.LineCount' =>      parse_num(h['line count'], :i),
      'Doc.CharacterCount' => parse_num(h['character count'], :i)
    }
    md.delete_if{|k,v| v.nil? }
    md
  end

  def base64 s
    return nil if s.nil? || s.empty?
    return Base64.encode64(s)
  end

  def id3lib_extract(fn)
    gem_require 'id3lib'
    t = ID3Lib::Tag.new(fn)
    time = t.year
    if t.date
      time = "#{time}-#{t.date[2,2]}-#{t.date[0,2]}"
    end
    {
      'Audio.Title' => t.title,
      'Audio.Subtitle' => t.subtitle,

      'Audio.Artist' => t.artist,
      'Audio.Band' => t.band,
      'Audio.Composer' => t.composer,
      'Audio.Performer' => t.performer,
      'Audio.Conductor' => t.conductor,
      'Audio.Lyricist' => t.lyricist,
      'Audio.RemixedBy' => t.remixed_by,
      'Audio.InterpretedBy' => t.interpreted_by,

      'Audio.Genre' => parse_genre(t.genre),
      'Audio.Grouping' => t.grouping,

      'Audio.Album' => t.album,
      'Audio.Publisher' => t.publisher,
      'Audio.ReleaseDate' => parse_time(time),
      'Audio.DiscNo' => parse_num(t.disc, :i),
      'Audio.TrackNo' => parse_num(t.track, :i),

      'Audio.Tempo' => parse_num(t.bpm, :i),
      'Audio.Comment' => t.comment,
      'Audio.Lyrics' => t.lyrics,
      'Audio.Image' => base64(t.find_all{|f| f[:id] == :APIC }.map{|f| f[:data] }[0])
    }
  end

  def extract_exif_tag(exif, filename, *tags)
    tag = tags.find{|t| exif[t] }
    value = exif[tag]
    if value and value =~ /\A\s*\(Binary data \d+ bytes, use -b option to extract\)\s*\Z/
      value = secure_filename(filename){|tfn|
        `exiftool -b -#{tag} #{tfn} 2>/dev/null`
      }
    end
    value
  end

  def extract_exif(filename)
    exif = {}
    raw_exif = secure_filename(filename){|tfn|
      `exiftool -s -t -c "%.6f" -d "%Y:%m:%dT%H:%M:%S%Z" #{tfn} 2>/dev/null`
    }.split("\n", 8).last
    raw_exif.strip.split("\n").each do |t|
      k,v = t.split("\t", 2)
      exif[k] = v
    end
    ex = lambda{|tags|  extract_exif_tag(exif, filename, *tags) }
    info = {
      'Image.Description' => ex[%w(ImageDescription Description Caption-Abstract Comment)],
      'Image.Creator' => ex[%w(Artist Creator By-line)],
      'Image.Editor' => ex[["Editor"]],
      'File.Software' => ex[["Software"]],
      'Image.OriginatingProgram' => ex[["OriginatingProgram"]],
      'Image.ExposureProgram' => ex[["ExposureProgram"]],
      'Image.Copyright' => ex[%w(Copyright CopyrightNotice CopyrightURL)],
      'Image.ISOSpeed' => parse_num(exif["ISO"], :f),
      'Image.Fnumber' => parse_num(exif["FNumber"], :f),
      'Image.Flash' => exif["FlashFired"] ?
                       exif["FlashFired"] == "True" : nil,
      'Image.FocalLength' => parse_num(exif["FocalLength"], :f),
      'Image.WhiteBalance' => ex[["WhiteBalance"]],
      'Image.CameraMake' => ex[['Make']],
      'Image.CameraModel' => ex[['Model']],
      'Image.Title' => ex[['Title']],
      'Image.ColorMode' => ex[['ColorMode']],
      'Image.ColorSpace' => ex[['ColorSpace']],

      'Image.EXIF' => raw_exif,

      'Location.Latitude' => parse_num(exif['GPSLatitude'], :f),
      'Location.Longitude' => parse_num(exif['GPSLongitude'], :f)
    }
    if exif["MeteringMode"]
      info['Image.MeteringMode'] = exif["MeteringMode"].split(/[^a-z]/i).map{|s|s.capitalize}.join
    end
    if t = exif["ModifyDate"]
      info['Image.Date'] =
      info['Image.Modified'] = parse_time(t.split(":",3).join("-"))
    end
    if t = exif["DateCreated"]
      info['Image.Date'] =
      info['Image.DateCreated'] = parse_time(t.split(":",3).join("-"))
    end
    if t = exif["DateTimeCreated"]
      info['Image.Date'] =
      info['Image.DateTimeCreated'] = parse_time(t.split(":",3).join("-"))
    end
    info['Image.Date'] = info['Image.Date'].dup if info['Image.Date']
    if t = exif["DateTimeOriginal"]
      info['Image.DateTimeOriginal'] = parse_time(t.split(":",3).join("-"))
    end
    if exif['ExposureTime']
      d,n = exif['ExposureTime'].split("/")
      n ||= 1.0
      info['Image.ExposureTime'] = d.to_f / n.to_f
    end
    info
  end

  def extract_dcraw(filename)
    hash = {}
    secure_filename(filename){|tfn| `dcraw -i -v #{tfn}` }.strip.split("\n").
    each do |t|
      k,v = t.split(/:\s*/, 2)
      hash[k] = v
    end
    w, h = hash["Output size"].split("x",2).map{|s| parse_num(s.strip, :f) }
    t = hash
    info = {
      'Image.Width' => w,
      'Image.Height' => h,

      'Image.FilterPattern' => t['Filter pattern'],
      'Image.FocalLength' => parse_num(t['Focal length'], :f),
      'Image.ISOSpeed' => parse_num(t['ISO speed'], :f),
      'Image.CameraModel' => t['Camera'],
      'Image.ComponentCount' => parse_num(t['Raw colors'], :i),
      'Image.Fnumber' => parse_num(t['Aperture'], :f)
    }
    if t['Shutter']
      d,n = t['Shutter'].split("/")
      n ||= 1.0
      info['Image.ExposureTime'] = d.to_f / n.to_f
    end
    info
  end

  def pdfinfo_extract_info(filename)
    ids = secure_filename(filename){|tfn| `pdfinfo #{tfn}` }.strip.split("\n").
    map{|r|
      k,v = r.split(":",2)
      k = k.downcase
      v = parse_val(v.strip)
      [k,v]
    }
    i = Hash[*ids.flatten]
    if i['page size']
      w,h = i['page size'].gsub(/[^0-9.]/, ' ').strip.split(/\s+/,2)
      wmm = w.to_f.points_to_mm
      hmm = h.to_f.points_to_mm
      i['page_size'] = i['page size'].scan(/\(([^)]+)\)/).flatten[0]
      i['width'] = wmm
      i['height'] = hmm
      i['dimensions_unit'] = 'mm'
    end
    i
  end


  def citeseer_extract(title)
    require 'metadata/citeseer'
    h = CiteSeer.get_info(title)
    return h if h.empty?
    m = {}
    m['Doc.Title'] = h['title']
    m['Doc.Author'] = (h['creator'] || h['author'])
    m['Doc.Description'] = h['description']
    m['Doc.Publisher'] = h['publisher']
    m['Doc.Contributor'] = h['contributor']
    m['Doc.Subject'] = h['subject']
    m['Doc.Source'] = h['source'] || h['ee']
    m['Doc.CiteSeerURL'] = h['identifier']
    m['Doc.Language'] = h['language']
    m['Doc.Publication'] = h['book'] || h['booktitle'] || h['journal']
    m['Doc.PublicationPages'] = h['pages']
    m['Doc.Citations'] = h['citations']
    m['Doc.Published'] = parse_time(h['date'] || h['year'])
    m['Doc.CiteSeerIdentifier'] = h['bibtex_id']

    m.delete_if{|k,v| !v }
    m
  end

  def dblp_extract(title)
    require 'metadata/dblp'
    h = DBLP.get_info(title)
    return h if h.empty?
    m = {}
    m['Doc.Title'] = h['title']
    m['Doc.Author'] = h['author']
    m['Doc.Description'] = h['description']
    m['Doc.Publisher'] = h['publisher']
    m['Doc.Contributor'] = h['contributor']
    m['Doc.Subject'] = h['subject']
    m['Doc.Source'] = h['ee']
    m['Doc.CrossRef'] = h['crossref']
    m['Doc.BibSource'] = h['bibsource']
    m['Doc.Language'] = h['language']
    m['Doc.Publication'] = h['book'] || h['booktitle'] || h['journal']
    m['Doc.PublicationPages'] = h['pages']
    m['Doc.Published'] = parse_time(h['date'] || h['year'])
    m['Doc.BibTexType'] = h['bibtex_type']
    m['Doc.DBLPIdentifier'] = h['bibtex_id']

    m.delete_if{|k,v| !v }
    m
  end



  # Create a link to `filename' with a secure filename and yield it.
  # Unlinks secure filename after yield returns.
  #
  # This is needed because of filenames like "-h".
  #
  # If the filename doesn't begin with a dash, passes it in
  # double-quotes with double-quotes and dollar signs in
  # filename escaped.
  #
  def secure_filename(filename)
    require 'fileutils'
    if filename =~ /^-/
      dirname = File.dirname(File.expand_path(filename))
      tfn = "/tmp/" + temp_filename + (File.extname(filename) || "").
            gsub(/[^a-z0-9_.]/i, '_') # PAA RAA NOO IAA
      begin
        FileUtils.ln(filename, tfn)
      rescue
        FileUtils.cp(filename, tfn) # different fs for /tmp
      end
      yield(tfn)
    else # trust the filename to not blow up in our face
      yield(%Q("#{filename.gsub(/[$"]/, "\\\\\\0")}"))
    end
  ensure
    File.unlink(tfn) if tfn and File.exist?(tfn)
  end

  def temp_filename
    "metadata_temp_#{Process.pid}_#{Thread.current.object_id}_#{Time.now.to_f}"
  end

  def parse_val(v)
    case v
    when /^[0-9]+$/ then v.to_i
    when /^[0-9]+(\.[0-9]+)?$/ then v.to_f
    else
      v
    end
  end


  def parse_num(s, cast=nil)
    if s.is_a? Numeric
      return (
        case cast
        when :f
          s.to_f
        when :i
          s.to_i
        else
          s
        end
      )
    end
    return nil if s.nil? or s.empty? or not s.scan(/[0-9]+/)[0]
    case cast
    when :i
      num = nil
      s.sub(/[0-9]+/){|h| num = h }
      if num
        num.to_i
      else
        nil
      end
    when :f
      num = nil
      s.sub(/[0-9]+(\.[0-9]+(e[-+]?[0-9]+)?)?/i){|h| num = h }
      if num
        num.to_f
      else
        nil
      end
    else
      s.scan(/[0-9]+/)[0]
    end
  end

  def parse_time(s)
    return s if s.is_a?(DateTime)
    return nil if s.nil? or s.empty?
    DateTime.parse(s.to_s)
  rescue
    t = s.to_s.scan(/\d{4}/)[0]
    if t.nil?
      t = s.to_s.scan(/\d{2}/)[0]
      unless t.nil?
        y = Time.now.year.to_s
        t = "#{t.to_i > y[-2,2].to_i ? y[0,2].to_i-1 : y[0,2]}#{t}-01-01"
        DateTime.parse(t)
      else
        nil
      end
    else
      t += "-01-01"
      DateTime.parse(t)
    end
  end

  def parse_genre(s)
    gem_require 'id3lib'
    return nil if s.nil? or s.empty?
    return s unless s =~ /^\(\d+\)/
    genre_num = s.scan(/\d+/).first.to_i
    ID3Lib::Info::Genres[genre_num] || s
  end
end