begin
  require 'rubygems'
rescue LoadError
end

require 'flacinfo'
require 'wmainfo'
require 'mp4info'
require 'apetag'
require 'id3lib'
require 'imlib2'

require 'iconv'
require 'fileutils'
require 'pathname'
require 'time'
require 'date'

require 'metadata/mime_info'
require 'metadata/bt'
require 'metadata/citeseer'
require 'metadata/dblp'


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

  def metadata
    @metadata ||= Metadata.extract(self, mimetype)
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

  def to_pn(*rest)
    pn = self
    pn = pn.join(*rest) unless rest.empty?
    pn
   end

end


class String

  def to_pn(*rest)
    pn = Pathname.new(self)
    pn = pn.join(*rest) unless rest.empty?
    pn
  end

  def chardet
    IO.popen("chardet", "r+"){|cd|
      cd.write(self[0,65536])
      cd.close_write
      cd.read.strip
    }
  end

  def to_utf8(charset=nil)
    us = nil
    charsets = [charset, 'utf-8', chardet,
      'utf-16', 'utf-32', 'shift-jis','euc-jp','iso8859-1','cp1252','big-5'].compact
    case us
    when /^(\x00\x00\xFE\xFF|\xFF\xFE\x00\x00)/
      charsets.unshift 'utf-32'
    when /^(\xFE\xFF|\xFF\xFE)/
      charsets.unshift 'utf-16'
    when /^\xEF\xBB\xBF/
      charsets.unshift 'utf-8'
    end
    charsets.find{|c|
      ((us = Iconv.iconv('utf-8', c, self)[0]) rescue false)
    }
    us ||= self.gsub(/[^0-9a-z._ '"\*\+\-]/,'?')
    us.gsub!(/^(\xFF\xFE|\xEF\xBB\xBF|\xFE\xFF)/, '') # strip UTF BOMs
    us
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

  attr_accessor(:quiet, :verbose,
                :sha1sum, :md5sum,
                :no_text, :guess_title, :guess_metadata,
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
  #   Metadata.quiet = true   # don't print out Ruby error messages
  #   Metadata.verbose = true # print out status messages to stderr
  # 
  # All strings are converted to UTF-8.
  #
  def extract(filename, mimetype=MimeInfo.get(filename.to_s), charset=nil)
    filename = filename.to_s
    mimetype = Mimetype[mimetype] unless mimetype.is_a?( Mimetype )
    mts = mimetype.ancestors
    mt = mts.shift
    rv = nil
    new_methods = public_methods(false)
    STDERR.puts "Processing #{filename}", " Metadata extraction" if verbose
    while mt.is_a?(Mimetype) and mt != Mimetype
      STDERR.puts "  Trying #{mt}" if verbose
      mn = mt.to_s.gsub(/[^a-z0-9]/i,"_")
      if new_methods.include?( mn )
        begin
          rv = __send__( mn, filename, charset )
          STDERR.puts "  OK" if verbose
          break
        rescue => e
          STDERR.puts(e, e.message, e.backtrace) unless quiet
        end
      end
      mt = mts.shift
    end
    unless rv
      STDERR.puts "  Falling back to extract" if verbose
      rv = extract_extract_info(filename)
    end
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
    if self.include_name
      rv['File.Name'] = enc_utf8(File.basename(filename), nil)
    end
    if self.include_path
      rv['File.Path'] = enc_utf8(File.dirname(filename), nil)
    end
    rv['File.Format'] ||= mimetype.to_s
    rv['File.Size'] = (
      if File.directory?(filename)
        Dir.entries(filename).size-2
      else
        File.size(filename)
      end)
    rv['File.Content'] = extract_text(filename, mimetype, charset, false) unless Metadata.no_text
    if guess_title or guess_metadata
      text = (rv['File.Content'] || extract_text(filename, mimetype, charset, false))
      guess = extract_guesses(text)
      if guess['Doc.Title'] and rv['Doc.Title'].nil? or rv['Doc.Title'] =~ /(^[a-z])|(\.(dvi|doc)$)/
        rv['Doc.Title'] = guess['Doc.Title']
      end
    end
    if use_citeseer and rv['Doc.Title'] and mimetype.to_s =~ /pdf|postscript|msword|oasis|sun|dvi|tex/
      rv.merge!(citeseer_extract(rv['Doc.Title']))
    end
    if use_dblp and rv['Doc.Title'] and mimetype.to_s =~ /pdf|postscript|msword|oasis|sun|dvi|tex/
      rv.merge!(dblp_extract(rv['Doc.Title']))
    end
    if guess_metadata
      rv['Doc.Citations'] ||= guess['Doc.Citations']
      rv['Doc.Description'] ||= guess['Doc.Description']
    end
    rv['File.Modified'] = parse_time(File.mtime(filename.to_s).iso8601)
    rv.delete_if{|k,v| v.nil? }
    rv
  end

  # Extracts text from a file by guessing mimetype and calling matching
  # extractor methods (which mostly call external programs to do their bidding.)
  #
  # The extracted text is converted to UTF-8.
  #
  def extract_text(filename, mimetype=MimeInfo.get(filename.to_s), charset=nil, layout=false)
    filename = filename.to_s
    mimetype = Mimetype[mimetype] unless mimetype.is_a?( Mimetype )
    mts = mimetype.ancestors
    mt = mts.shift
    new_methods = public_methods(false)
    STDERR.puts " Text extraction" if verbose
    while mt.is_a?(Mimetype) and mt != Mimetype
      STDERR.puts "  Trying #{mt}" if verbose
      mn = mt.to_s.gsub(/[^a-z0-9]/i,"_") + "__gettext"
      if new_methods.include?( mn )
        begin
          rv = __send__( mn, filename, charset, layout )
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


  def extract_guesses(text)
    return {} unless text
    guess = {}

    title = text.find{|l| l =~ /^[A-Z]/ }

    abstract = text.scan(/^Abstract\s*\n(.+)\n(\d*\.?\s*)Introduction\s*\n/im).
                    flatten.first

    references = text.scan(/^(References|Citations)\s*\n(.+)/im).flatten.last
    if references
      cites = parse_references(references)
    end
    
    guess['Doc.Title'] = title.strip if title and title.strip.size < 100
    guess['Doc.Description'] = abstract.strip if abstract
    guess['Doc.Citations'] = cites if cites and not cites.empty?
    guess
  end

  def parse_references(refs)
    cits = []
    done = false
    refs.scan(/\[([^\]]+)\]\s*([^\[]+)/m).each{|key, ref|
      ref.gsub!(/^[0-9]+$/m, '\n') # remove page numbers
      if ref.size > 400
        ref = ref.split(/\f/,2).first
        done = true
      end
      url = ref.scan(%r{http://\S+})[0]
      url.sub!(/[,.]\Z/,'') if url
      ar = ref.scan(/([^"“”]+)["“”]([^"“”]+)["“”](.+)/u)
      unless ar.empty?
        author, title, publisher = ar[0]
        author = author.strip.sub(/[,.]\Z/,'')
        publisher = publisher.strip.sub(/[,.]\Z/,'')
        title = title.strip.sub(/[,.]\Z/,'')
      end
      # guess where appendices begin
      cits << {'href' => url,
       'title' => title || author || publisher || ref,
       'rest' => "#{author} - #{publisher}"
      }
      break if done
    }
    cits
  end

  def audio_x_flac(fn, charset)
    m = nil
    begin
      m = FlacInfo.new(fn)
    rescue # FlacInfo fails for flacs with id3 tags
      return audio(fn, charset)
    end
    t = m.tags
    si = m.streaminfo
    len = si["total_samples"].to_f / si["samplerate"]
    md = {
      'Audio.Title' => enc_utf8(t['TITLE'], charset),
      'Audio.Artist' => enc_utf8(t['ARTIST'], charset),
      'Audio.Album' => enc_utf8(t['ALBUM'], charset),
      'Audio.Comment' => enc_utf8(t['COMMENT'], charset),
      'Audio.Bitrate' => File.size(fn)*8 / len,
      'Audio.Duration' => len,
      'Audio.Samplerate' => si["samplerate"],
      'Audio.VariableBitrate' => true,
      'Audio.Genre' => parse_genre(enc_utf8(t['GENRE'], charset)),
      'Audio.ReleaseDate' => parse_time(t['DATE']),
      'Audio.TrackNo' => parse_num(t['TRACKNUMBER'], :i),
      'Audio.Channels' => si["channels"]
    }
    ad = (audio(fn, charset) rescue {})
    ad.delete_if{|k,v| v.nil? }
    md.merge(ad)
  end

  def audio_mp4(fn, charset)
    m = MP4Info.open(fn)
    tn, total = m.TRKN
    md = {
      'Audio.Title' => enc_utf8(m.NAM, charset),
      'Audio.Artist' => enc_utf8(m.ART, charset),
      'Audio.Album' => enc_utf8(m.ALB, charset),
      'Audio.Bitrate' => m.BITRATE,
      'Audio.Duration' => m.SECS,
      'Audio.Samplerate' => m.FREQUENCY*1000,
      'Audio.VariableBitrate' => true,
      'Audio.Genre' => parse_genre(enc_utf8(m.GNRE, charset)),
      'Audio.ReleaseDate' => parse_time(m.DAY),
      'Audio.TrackNo' => parse_num(tn, :i),
      'Audio.AlbumTrackCount' => parse_num(total, :i),
      'Audio.Writer' => enc_utf8(m.WRT, charset),
      'Audio.Copyright' => enc_utf8(m.CPRT, charset),
      'Audio.Tempo' => parse_num(m.TMPO, :i)
    }
  end

  def audio_x_ms_wma(fn, charset)
    # hack hack hacky workaround
    m = WmaInfo.allocate
    m.instance_variable_set("@ext_info", {})
    m.__send__(:initialize, fn)
    t = m.tags
    si = m.info
    md = {
      'Audio.Title' => enc_utf8(t['Title'], charset),
      'Audio.Artist' => enc_utf8(t['Author'], charset),
      'Audio.Album' => enc_utf8(t['AlbumTitle'], charset),
      'Audio.AlbumArtist' => enc_utf8(t['AlbumArtist'], charset),
      'Audio.Bitrate' => si["bitrate"],
      'Audio.Duration' => si["playtime_seconds"],
      'Audio.Genre' => parse_genre(enc_utf8(t['Genre'], charset)),
      'Audio.ReleaseDate' => parse_time(t['Year']),
      'Audio.TrackNo' => parse_num(t['TrackNumber'], :i),
      'Audio.Copyright' => enc_utf8(t['Copyright'], charset),
      'Audio.VariableBitrate' => (si['IsVBR'] == 1)
    }
  end

  def audio_x_ape(fn, charset)
    m = ApeTag.new(fn)
    t = m.fields
    ad = (id3lib_extract(fn, charset) rescue {})
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

  def application_pdf(filename, charset)
    h = pdfinfo_extract_info(filename)
    charset = nil
    secure_filename(filename){|tfn|
      charset = `pdftotext #{tfn} - | head -c 65536`.chardet
      h['words'] = `pdftotext #{tfn} - | wc -w 2>/dev/null`.strip.to_i
    }
    if h['keywords']
      keywords = h['keywords'].split(/[,.]/).map{|s| enc_utf8(s.strip, charset) }.find_all{|s| not s.empty? }
    end
    {
      'Doc.Title', enc_utf8(h['title'], charset),
      'Doc.Author', enc_utf8(h['author'], charset),
      'Doc.Created', parse_time(h['creationdate']),
      'Doc.Subject', enc_utf8(h['subject'], charset),
      'Doc.Modified', parse_time(h['moddate']),
      'Doc.PageCount', h['pages'],
      'Doc.Keywords', keywords,
      'Doc.PageSizeName', h['page_size'],
      'Doc.WordCount', h['words'],
      'Doc.Charset', charset,
      'Image.Width', h['width'],
      'Image.Height', h['height'],
      'Image.DimensionUnit', 'mm'
    }
  end

  def application_postscript(filename, charset)
    pdf = File.join(File.dirname(filename.to_s), File.basename(filename.to_s)+"-temp.pdf")
    if File.exist?(pdf)
      application_pdf(pdf, charset).merge(extract_extract_info(filename))
    else
      extract_extract_info(filename)
    end
  end
  alias_method :application_x_gzpostscript, :application_postscript

  def text_html(filename, charset)
    words = secure_filename(filename){|tfn|
      `html2text #{tfn} | wc -w 2>/dev/null`
    }.strip.to_i
    charset = (File.read(filename, 65536) || "").chardet
    {
      'Doc.WordCount' => words,
      'Doc.Charset' => charset
    }
  end

  def text(filename, charset)
    words = secure_filename(filename){|tfn| `wc -w #{tfn} 2>/dev/null` }.strip.to_i
    charset = (File.read(filename, 65536) || "").chardet
    {
      'Doc.WordCount' => words,
      'Doc.Charset' => charset
    }
  end

  def audio(filename, charset)
    id3 = (id3lib_extract(filename, charset) rescue {})
    h = mplayer_extract_info(filename)
    info = {
      'Audio.Duration', (h['length'].to_i > 0) ? parse_num(h['length'], :f) : nil,
      'Audio.Bitrate', h['audio_bitrate'] && h['audio_bitrate'] != '0' ?
                       parse_num(h['audio_bitrate'], :i) / 1000.0 : nil,
      'Audio.Codec', enc_utf8(h['audio_format'], charset),
      'Audio.Samplerate', parse_num(h['audio_rate'], :i),
      'Audio.Channels', parse_num(h['audio_nch'], :i),
      
      'Audio.Title', enc_utf8(h['title'] || h['name'], charset),
      'Audio.Artist', enc_utf8(h['artist'] || h['author'], charset),
      'Audio.Album', enc_utf8(h['album'], charset),
      'Audio.ReleaseDate', parse_time(h['date'] || h['creation date'] || h['year']),
      'Audio.Comment', enc_utf8(h['comment'] || h['comments'], charset),
      'Audio.TrackNo', parse_num(h['track'], :i),
      'Audio.Copyright', enc_utf8(h['copyright'], charset),
      'Audio.Software', enc_utf8(h['software'], charset),
      'Audio.Genre', parse_genre(enc_utf8(h['genre'], charset))
    }
    id3.delete_if{|k,v| v.nil? }
    info.merge(id3)
  end
  
  def video(filename, charset)
    id3 = (id3lib_extract(filename, charset) rescue {})
    h = mplayer_extract_info(filename)
    info = {
      'Image.Width', parse_num(h['video_width'], :i),
      'Image.Height', parse_num(h['video_height'], :i),
      'Image.DimensionUnit', 'px',
      'Video.Duration', (h['length'].to_i > 0) ? parse_num(h['length'], :f) : nil,
      'Video.Framerate', parse_num(h['video_fps'], :f),
      'Video.Bitrate', h['video_bitrate'] && h['video_bitrate'] != '0' ?
                       parse_num(h['video_bitrate'], :i) / 1000.0 : nil,
      'Video.Codec', enc_utf8(h['video_format'], charset),
      'Audio.Bitrate', h['audio_bitrate'] && h['audio_bitrate'] != '0' ?
                       parse_num(h['audio_bitrate'], :i) / 1000.0 : nil,
      'Audio.Codec', enc_utf8(h['audio_format'], charset),
      'Audio.Samplerate', parse_num(h['audio_rate'], :i),
      'Audio.Channels', parse_num(h['audio_nch'], :i),
      
      'Video.Title', enc_utf8(h['title'] || h['name'], charset),
      'Video.Artist', enc_utf8(h['artist'] || h['author'], charset),
      'Video.Album', enc_utf8(h['album'], charset),
      'Video.ReleaseDate', parse_time(h['date'] || h['creation date'] || h['year']),
      'Video.Comment', enc_utf8(h['comment'] || h['comments'], charset),
      'Video.TrackNo', parse_num(h['track'], :i),
      'Video.Genre', parse_genre(enc_utf8(h['genre'], charset)),
      'Video.Copyright', enc_utf8(h['copyright'], charset),
      'Video.Software', enc_utf8(h['software'], charset),
      'Video.Demuxer', enc_utf8(h['demuxer'], charset)
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

  def video_x_ms_wmv(filename, charset)
    h = video(filename, charset)
    wma = audio_x_ms_wma(filename, charset)
    %w(
      Bitrate Artist Title Album Genre ReleaseDate TrackNo VariableBitrate
    ).each{|t|
      h['Video.'+t] = wma['Audio.'+t]
    }
    %w(Samplerate).each{|t|
      h['Audio.'+t] = wma['Audio.'+t]
    }
    h
  end
  alias_method('video_x_ms_asf', 'video_x_ms_wmv')

  def image(filename, charset)
    begin
      img = Imlib2::Image.load(filename.to_s)
      w = img.width
      h = img.height
      id_out = ""
      img.delete!
    rescue Exception
      id_out = secure_filename(filename){|tfn| `identify #{tfn}` }
      w,h = id_out.scan(/[0-9]+x[0-9]+/)[0].split("x",2)
    end
    exif = (extract_exif(filename, charset) rescue {})
    info = {
      'Image.Width' => parse_val(w),
      'Image.Height' => parse_val(h),
      'Image.DimensionUnit' => 'px',
      'Image.LayerCount' => [id_out.split("\n").size, 1].max
    }.merge(exif)
    info
  end

  def image_gif(filename, charset)
    id_out = secure_filename(filename){|tfn| `identify #{tfn}` }
    w,h = id_out.scan(/[0-9]+x[0-9]+/)[0].split("x",2)
    exif = (extract_exif(filename, charset) rescue {})
    info = {
      'Image.Width' => parse_val(w),
      'Image.Height' => parse_val(h),
      'Image.DimensionUnit' => 'px',
      'Image.FrameCount' => [id_out.split("\n").size, 1].max
    }.merge(exif)
    info
  end

  def image_x_dcraw(filename, charset)
    exif = (extract_exif(filename, charset) rescue {})
    dcraw = extract_dcraw(filename)
    info = {
      'Image.Frames' => 1,
      'Image.DimensionUnit' => 'px'
    }.merge(exif).merge(dcraw)
    info
  end

  def application_x_bittorrent(fn, charset)
    h = File.read(fn).bdecode
    charset ||= h['encoding']
    i = h['info']
    name = i['name.utf-8'] || enc_utf8(i['name'], charset)
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
            fh = {"path" => (up || enc_utf8(pt, charset)),
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

      'File.Software' => enc_utf8(h['created by'], charset),
      'Doc.Created' => parse_time(Time.at(h['creation date']).iso8601),
      'BitTorrent.Comment' => enc_utf8(h['comment'], charset),
      'BitTorrent.Announce' => enc_utf8(h['announce'], charset),
      'BitTorrent.AnnounceList' => h['announce-list'],
      'BitTorrent.Nodes' => h['nodes']
    }
  end


  def text__gettext(filename, charset, layout=false)
    enc_utf8((File.read(filename) || ""), charset)
  end

  def text_html__gettext(filename, charset, layout=false)
    enc_utf8(secure_filename(filename){|tfn| `unhtml #{tfn}` }, charset)
  end

  def application_pdf__gettext(filename, charset, layout=false)
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
    enc_utf8(str, "UTF-8")
  end
  
  def application_postscript__gettext(filename, charset, layout=false)
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
    enc_utf8(str, "ISO-8859-1") # pstotext outputs iso-8859-1
  end

  def application_x_gzpostscript__gettext(filename, charset, layout=false)
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
    enc_utf8(str, "ISO-8859-1") # pstotext outputs iso-8859-1
  end
  
  def application_msword__gettext(filename, charset, layout=false)
    secure_filename(filename){|sfn| enc_utf8(`antiword #{sfn}`, charset) }
  end
  
  def application_rtf__gettext(filename, charset, layout=false)
    secure_filename(filename){|sfn| enc_utf8(`catdoc #{sfn}`, charset) }
  end
  
  def application_vnd_ms_powerpoint__gettext(filename, charset, layout=false)
    secure_filename(filename){|sfn| enc_utf8(`catppt #{sfn}`, charset) }
  end

  def application_vnd_ms_excel__gettext(filename, charset, layout=false)
    secure_filename(filename){|sfn| enc_utf8(`xls2csv -d UTF-8 #{sfn}`, charset) }
  end

  

  open_office_types = %w(
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

  office_types = %w(
  application/msword
  application/vnd.ms-powerpoint
  application/vnd.ms-excel
  application/rtf
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

  (open_office_types).each{|t|
    create_text_extractor(t) do |filename, charset, layout|
      pdf = File.join(File.dirname(filename.to_s), File.basename(filename.to_s)+"-temp.pdf")
      if File.exist?(pdf)
        application_pdf__gettext(pdf, charset, layout)
      else
        nil
      end
    end
  }
  
  (open_office_types + office_types).each{|t|
    create_info_extractor(t) do |filename, charset|
      pdf = File.join(File.dirname(filename.to_s), File.basename(filename.to_s)+"-temp.pdf")
      if File.exist?(pdf)
        application_pdf(pdf, charset).merge(extract_extract_info(filename))
      else
        extract_extract_info(filename)
      end
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
    hash.each{|k,v|
      if k =~ /^clip_info_name/
        hash[v.downcase] = hash[k.sub("name", "value")]
      end
    }
    hash
  end

  def extract_extract_info(filename)
    arr = secure_filename(filename){|tfn| `extract #{tfn}` }.strip.split("\n").map{|s| s.split(" - ",2) }
    h = arr.to_hash
    filenames = arr.find_all{|k,v| k == 'filename' }.map{|k,v| enc_utf8(v, nil) }
    keywords = arr.find_all{|k,v| k == 'keywords' }.map{|k,v| enc_utf8(v, nil) }
    revisions = arr.find_all{|k,v| k == 'revision history' }.map{|k,v| enc_utf8(v, nil) }
    {
      'Doc.Title', enc_utf8(h['title'], nil),
      'Doc.Subject', enc_utf8(h['subject'], nil),
      'Doc.Author', enc_utf8(h['creator'], nil),
      'Doc.LastSavedBy', enc_utf8(h['last saved by'], nil),

      'Doc.Language', enc_utf8(h['language'], nil),
      
      'Doc.Artist', enc_utf8(h['artist'], nil),
      'Doc.Genre', enc_utf8(h['genre'], nil),
      'Doc.Album', enc_utf8(h['album'], nil),
      'Doc.Language', enc_utf8(h['language'], nil),

      'Doc.Created', parse_time(h['creation date']),
      'Doc.Modified', parse_time(h['modification date'] || h['date']),
      'Doc.RevisionHistory', revisions.empty? ? nil : revisions,

      'Doc.Description', enc_utf8(h['description'], nil),
      'Doc.Keywords', keywords.empty? ? nil : keywords,

      'File.Software', enc_utf8(h['software'] || h['generator'], nil),
      'Doc.Template', enc_utf8(h['template'], nil),
      
      'Archive.Contents', filenames.empty? ? nil : filenames,

      'Doc.WordCount',      parse_num(h['word count'], :i),
      'Doc.PageCount',      parse_num(h['page count'], :i),
      'Doc.ParagraphCount', parse_num(h['paragraph count'], :i),
      'Doc.LineCount',      parse_num(h['line count'], :i),
      'Doc.CharacterCount', parse_num(h['character count'], :i)
    }
  end

  def id3lib_extract(fn, charset)
    t = ID3Lib::Tag.new(fn)
    time = t.year
    if t.date
      time = "#{time}-#{t.date[2,2]}-#{t.date[0,2]}"
    end
    {
      'Audio.Title' => enc_utf8(t.title, charset),
      'Audio.Subtitle' => enc_utf8(t.subtitle, charset),

      'Audio.Artist' => enc_utf8(t.artist, charset),
      'Audio.Band' => enc_utf8(t.band, charset),
      'Audio.Composer' => enc_utf8(t.composer, charset),
      'Audio.Performer' => enc_utf8(t.performer, charset),
      'Audio.Conductor' => enc_utf8(t.conductor, charset),
      'Audio.Lyricist' => enc_utf8(t.lyricist, charset),
      'Audio.RemixedBy' => enc_utf8(t.remixed_by, charset),
      'Audio.InterpretedBy' => enc_utf8(t.interpreted_by, charset),

      'Audio.Genre' => parse_genre(enc_utf8(t.genre, charset)),
      'Audio.Grouping' => enc_utf8(t.grouping, charset),

      'Audio.Album' => enc_utf8(t.album, charset),
      'Audio.Publisher' => enc_utf8(t.publisher, charset),
      'Audio.ReleaseDate' => parse_time(time),
      'Audio.DiscNo' => parse_num(t.disc, :i),
      'Audio.TrackNo' => parse_num(t.track, :i),

      'Audio.Tempo' => parse_num(t.bpm, :i),
      'Audio.Comment' => enc_utf8(t.comment, charset),
      'Audio.Lyrics' => enc_utf8(t.lyrics, charset),
      'Audio.Image' => t.find_all{|f| f[:id] == :APIC }.map{|f| f[:data] }[0]
    }
  end
  
  def extract_exif(filename, charset=nil)
    exif = {}
    raw_exif = secure_filename(filename){|tfn|
      `exiftool -s -t -d "%Y:%m:%dT%H:%M:%S%Z" #{tfn} 2>/dev/null`
    }.split("\n", 8).last
    raw_exif.strip.split("\n").each do |t|
      k,v = t.split("\t", 2)
      exif[k] = v
    end
    info = {
      'Image.Description' => enc_utf8( exif["ImageDescription"] || exif["Description"] || exif["Caption-Abstract"] || exif["Comment"], charset ),
      'Image.Creator' => enc_utf8( exif["Artist"] || exif["Creator"] || exif["By-line"], charset ),
      'Image.Editor' => enc_utf8( exif["Editor"], charset ),
      'File.Software' => enc_utf8( exif["Software"], charset ),
      'Image.OriginatingProgram' => enc_utf8(exif["OriginatingProgram"], charset ),
      'Image.ExposureProgram' => enc_utf8(exif["ExposureProgram"], charset),
      'Image.Copyright' => enc_utf8(exif["Copyright"] || exif["CopyrightNotice"] || exif["CopyrightURL"], charset),
      'Image.ISOSpeed' => parse_num(exif["ISO"], :f),
      'Image.Fnumber' => parse_num(exif["FNumber"], :f),
      'Image.Flash' => exif["FlashFired"] ?
                       enc_utf8(exif["FlashFired"], charset) == "True" : nil,
      'Image.FocalLength' => parse_num(exif["FocalLength"], :f),
      'Image.WhiteBalance' => enc_utf8(exif["WhiteBalance"], charset),
      'Image.CameraMake' => enc_utf8(exif['Make'], charset),
      'Image.CameraModel' => enc_utf8(exif['Model'], charset),
      'Image.Title' => enc_utf8(exif['Title'], charset),
      'Image.ColorMode' => enc_utf8(exif['ColorMode'], charset),
      'Image.ColorSpace' => enc_utf8(exif['ColorSpace'], charset),

      'Image.EXIF' => enc_utf8(raw_exif, charset),
      
      'Location.Latitude' => enc_utf8(exif['GPSLatitude'], charset),
      'Location.Longitude' => enc_utf8(exif['GPSLongitude'], charset)
    }
    if exif["MeteringMode"]
      info['Image.MeteringMode'] = enc_utf8(exif["MeteringMode"].split(/[^a-z]/i).map{|s|s.capitalize}.join, charset)
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
    w, h = hash["Output size"].split("x",2).map{|s| parse_num(s.strip, :i) }
    t = hash
    info = {
      'Image.Width', w,
      'Image.Height', h,
      
      'Image.FilterPattern', t['Filter pattern'],
      'Image.FocalLength', parse_num(t['Focal length'], :f),
      'Image.ISOSpeed', parse_num(t['ISO speed'], :f),
      'Image.CameraModel', enc_utf8(t['Camera'], nil),
      'Image.ComponentCount', parse_num(t['Raw colors'], :i),
      'Image.Fnumber', parse_num(t['Aperture'], :f)
    }
    if t['Shutter']
      d,n = t['Shutter'].split("/")
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
    m['Doc.PublicationName'] = h['book'] || h['booktitle'] || h['journal']
    m['Doc.PublicationPages'] = h['pages']
    m['Doc.Citations'] = h['citations']
    m['Doc.Published'] = parse_time(h['date'] || h['year'])
    m['Doc.CiteSeerIdentifier'] = h['bibtex_id']

    m.delete_if{|k,v| !v }
    m
  end

  def dblp_extract(title)
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
    m['Doc.PublicationName'] = h['book'] || h['booktitle'] || h['journal']
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
    when /^[0-9]+$/: v.to_i
    when /^[0-9]+(\.[0-9]+)?$/: v.to_f
    else
      v
    end
  end

  def enc_utf8(s, charset)
    return nil if s.nil? or s.empty?
    s.to_utf8(charset)
  end

  def parse_num(s, cast=nil)
    return s if s.is_a? Numeric
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
    return nil if s.nil? or s.empty?
    return s unless s =~ /^\(\d+\)/
    genre_num = s.scan(/\d+/).first.to_i
    ID3Lib::Info::Genres[genre_num] || s
  end


end
