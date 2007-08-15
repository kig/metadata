begin
  require 'rubygems'
rescue LoadError
end  

require 'metadata/mp3info'
require 'metadata/mime_info'
require 'imlib2'
require 'iconv'
require 'time'
require 'pathname'
require 'fileutils'


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
    charsets = [charset, 'utf-8',
      chardet,
      'shift-jis','euc-jp','iso8859-1','cp1252','big-5'].compact
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

  # Extracts metadata from a file.
  #
  # Metadata.extract('foo.png')
  #
  def extract(filename, mimetype=MimeInfo.get(filename.to_s), charset=nil)
    filename = filename.to_s
    mimetype = Mimetype[mimetype] unless mimetype.is_a?( Mimetype )
    mts = mimetype.ancestors
    mt = mts.shift
    rv = nil
    new_methods = public_methods(false)
    while mt.is_a?(Mimetype)
      mn = mt.to_s.gsub(/[^a-z0-9]/i,"_")
      if new_methods.include?( mn )
        begin
          rv = __send__( mn, filename, charset )
          break
        rescue => e
          puts e, e.message, e.backtrace
        end
      end
      mt = mts.shift
    end
    rv ||= extract_extract_info(filename)
    rv['File.Format'] = mimetype.to_s
    rv['File.Size'] = File.size(filename.to_s)
    rv['File.Content'] = extract_text(filename, mimetype, charset, false)
    rv['File.Modified'] = parse_time(File.mtime(filename.to_s).iso8601)
    rv
  end

  def extract_text(filename, mimetype=MimeInfo.get(filename.to_s), charset=nil, layout=false)
    filename = filename.to_s
    mimetype = Mimetype[mimetype] unless mimetype.is_a?( Mimetype )
    mt = mimetype
    new_methods = public_methods(false)
    while mt.is_a?(Mimetype)
      mn = mt.to_s.gsub(/[^a-z0-9]/i,"_") + "__gettext"
      if new_methods.include?( mn )
        begin
          return __send__( mn, filename, charset, layout )
        rescue => e
          puts e, e.message, e.backtrace
        end
      end
      mt = mt.ancestors[1]
    end
    ""
  end

  alias_method :[], 'extract'




  def audio_mpeg(fn, charset)
    Mp3Info.open(fn) do |m|
      t = m.tag
      md = {
        'Audio.Title' => enc_utf8(t['title'], charset),
        'Audio.Artist' => enc_utf8(t['artist'], charset),
        'Audio.Album' => enc_utf8(t['album'], charset),
        'Audio.Bitrate' => m.bitrate.to_i*1000,
        'Audio.Duration' => m.length.to_f,
        'Audio.Samplerate' => m.samplerate.to_i,
        'Audio.VariableBitrate' => m.vbr,
        'Audio.Genre' => enc_utf8(t['genre_s'], charset),
        'Audio.ReleaseDate' => parse_time(t['year']),
        'Audio.TrackNo' => parse_num(t['tracknum'])
      }
    end
  end

  def application_pdf(fname, charset)
    h = pdfinfo_extract_info(fname)
    charset = `pdftotext #{fname.dump} - | head -c 65536`.chardet
    h['words'] = `pdftotext #{fname.dump} - | wc -w 2>/dev/null`.strip.to_i
    {
      'Doc.Title', enc_utf8(h['title'], charset),
      'Doc.Author', enc_utf8(h['author'], charset),
      'Doc.Created', parse_time(h['creationdate']),
      'Doc.Modified', parse_time(h['moddate']),
      'Doc.PageCount', h['pages'],
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
      extract_extract_info(filename).merge(application_pdf(pdf, charset))
    else
      extract_extract_info(filename)
    end
  end

  def text_html(fname, charset)
    words = `html2text #{fname.dump} | wc -w 2>/dev/null`.strip.to_i
    charset = (File.read(fname, 65536) || "").chardet
    {
      'Doc.WordCount' => words,
      'Doc.Charset' => charset
    }
  end

  def text(fname, charset)
    words = `wc -w #{fname.dump} 2>/dev/null`.strip.to_i
    charset = (File.read(fname, 65536) || "").chardet
    {
      'Doc.WordCount' => words,
      'Doc.Charset' => charset
    }
  end

  def video(fname, charset)
    h = mplayer_extract_info(fname)
    info = {
      'Image.Width', h['video_width'],
      'Image.Height', h['video_height'],
      'Image.DimensionUnit', 'px',
      'Video.Length', (h['length'].to_i > 0) ? h['length'] : nil,
      'Video.Framerate', h['video_fps'],
      'Video.Bitrate', h['video_bitrate'],
      'Video.Codec', h['video_format'].to_s,
      'Audio.Bitrate', h['audio_bitrate'],
      'Audio.Codec', h['audio_format'].to_s,
      'Audio.Samplerate', h['audio_rate']
    }
  end

  alias_method('application_x_flash_video', 'video')

  def image(fname, charset)
    begin
      img = Imlib2::Image.load(fname.to_s)
      w = img.width
      h = img.height
      id_out = ""
      img.delete!
    rescue Exception
      id_out = `identify #{fname.dump}`
      w,h = id_out.scan(/[0-9]+x[0-9]+/)[0].split("x",2)
    end
    exif = extract_exif(fname, charset)
    info = {
      'Image.Width' => parse_val(w),
      'Image.Height' => parse_val(h),
      'Image.DimensionUnit' => 'px',
      'Image.Frames' => id_out.split("\n").size
    }.merge(exif)
    info
  end

  def image_x_dcraw(fname, charset)
    exif = extract_exif(fname, charset)
    dcraw = extract_dcraw(fname)
    w, h = dcraw["Output size"].split("x",2).map{|s| s.strip }
    info = {
      'Image.Width' => parse_val(w),
      'Image.Height' => parse_val(h),
      'Image.Frames' => 1,
      'Image.DimensionsUnit' => 'px'
    }.merge(exif)
    info
  end

  def text__gettext(filename, charset, layout=false)
    enc_utf8((File.read(filename) || ""), charset)
  end

  def text_html__gettext(filename, charset, layout=false)
    enc_utf8(`unhtml #{filename.dump}`, charset)
  end

  def application_pdf__gettext(filename, charset, layout=false)
    page = 0
    str = `pdftotext #{layout ? "-layout " : ""}-enc UTF-8 #{filename.dump} -`
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
    str = `pstotext #{filename.dump}`
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
    enc_utf8(`antiword #{filename.dump}`, charset)
  end
  
  def application_rtf__gettext(filename, charset, layout=false)
    enc_utf8(`catdoc #{filename.dump}`, charset)
  end
  
  def application_vnd_ms_powerpoint__gettext(filename, charset, layout=false)
    enc_utf8(`catppt #{filename.dump}`, charset)
  end

  def application_vnd_ms_excel__gettext(filename, charset, layout=false)
    enc_utf8(`xls2csv -d UTF-8 #{filename.dump}`, charset)
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
        ''
      end
    end
  }
  
  (open_office_types + office_types).each{|t|
    create_info_extractor(t) do |filename, charset|
      pdf = File.join(File.dirname(filename.to_s), File.basename(filename.to_s)+"-temp.pdf")
      if File.exist?(pdf)
        extract_extract_info(filename).merge(application_pdf(pdf, charset))
      else
        extract_extract_info(filename)
      end
    end
  }
  
  def mplayer_extract_info(fname)
    mplayer = `which mplayer32`.strip
    mplayer = `which mplayer`.strip if mplayer.empty?
    mplayer = "mplayer" if mplayer.empty?
    output = IO.popen("#{mplayer.dump} -quiet -identify -vo null -ao null -frames 0 -playlist - 2>/dev/null", "r+"){|mp|
      mp.puts fname
      mp.close_write
      mp.read
    }
    ids = output.split("\n").grep(/^ID_/).map{|t|
      k,v, = t.split("=",2)
      k = k.downcase[3..-1]
      v = parse_val(v)
      [k,v]
    }
    Hash[*ids.flatten]
  end

  def extract_extract_info(fname)
    h = `extract #{fname.dump}`.strip.split("\n").map{|s| s.split(" - ",2) }.to_hash
    {
      'Doc.Title', enc_utf8(h['title'], nil),
      'Doc.Language', enc_utf8(h['language'], nil),
      'Doc.Subject', enc_utf8(h['subject'], nil),
      'Doc.Author', enc_utf8(h['creator'], nil),
      'Doc.Created', parse_time(h['date'] || h['creation date']),
      'Doc.Modified', parse_time(h['modification date']),
      'Doc.Description', enc_utf8(h['description'], nil),
      'File.Software', enc_utf8(h['software'], nil),
      'Doc.WordCount', h['word count'].to_i
    }
  end

  def extract_exif(fname, charset=nil)
    exif = {}
    raw_exif = `exiftool -s -t -d "%Y:%m:%dT%H:%M:%S%Z" #{fname.dump}`.split("\n", 8).last
    raw_exif.strip.split("\n").each do |t|
      k,v = t.split("\t", 2)
      exif[k] = v
    end
    info = {
      'Image.Description' => enc_utf8( exif["ImageDescription"] || exif["Description"] || exif["Caption-Abstract"], charset ),
      'Image.Creator' => enc_utf8( exif["Artist"] || exif["Creator"] || exif["By-line"], charset ),
      'File.Software' => enc_utf8( exif["Software"], charset ),
      'Image.OriginatingProgram' => enc_utf8(exif["OriginatingProgram"], charset ),
      'Image.ExposureProgram' => enc_utf8(exif["ExposureProgram"], charset),
      'Image.ExposureTime' => enc_utf8(exif["ExposureTime"], charset),
      'Image.Copyright' => enc_utf8(exif["Copyright"] || exif["CopyrightNotice"] || exif["CopyrightURL"], charset),
      'Image.ISOSpeed' => exif["ISO"].to_i,
      'Image.Fnumber' => exif["FNumber"].to_f,
      'Image.Flash' => enc_utf8(exif["FlashFired"], charset) == "True",
      'Image.FocalLength' => enc_utf8(exif["FocalLength"], charset),
      'Image.WhiteBalance' => enc_utf8(exif["WhiteBalance"], charset),
      'Image.CameraMake' => enc_utf8(exif['Make'], charset),
      'Image.CameraModel' => enc_utf8(exif['Model'], charset),
      'Image.Title' => enc_utf8(exif['Title'], charset),
      'Image.EXIF' => enc_utf8(raw_exif, charset),
      'Location.Latitude' => enc_utf8(exif['GPSLatitude'], charset),
      'Location.Longitude' => enc_utf8(exif['GPSLongitude'], charset)
    }
    if exif["MeteringMode"]
      info['Image.MeteringMode'] = enc_utf8(exif["MeteringMode"].split(/[^a-z]/i).map{|s|s.capitalize}.join, charset)
    end
    if t = exif["ModifyDate"]
      info['Image.Date'] =
      info['Image.ModifyDate'] = parse_time(t.split(":",3).join("-"))
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
    info
  end

  def extract_dcraw(fname)
    h = {}
    `dcraw -i -v #{fname.dump}`.strip.split("\n").each do |t|
      k,v = t.split(/:\s*/, 2)
      h[k] = v
    end
    h
  end

  def pdfinfo_extract_info(fname)
    ids = `pdfinfo #{fname.dump}`.strip.split("\n").map{|r|
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
      i['page_size'] = i['page size'].scan(/\(([^)]+)\)/)[0].to_s
      i['width'] = wmm
      i['height'] = hmm
      i['dimensions_unit'] = 'mm'
    end
    i
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

  def parse_num(s)
    return s if s.is_a? Numeric
    return nil if s.nil? or s.empty?
    s.scan(/[0-9]+/)[0]
  end

  def parse_time(s)
    return s if s.is_a? DateTime
    return nil if s.nil? or s.empty?
    DateTime.parse(s.to_s)
  rescue
    t = s.to_s.scan(/[0-9]{4}/)[0]
    unless t.nil?
      t += "-01-01"
      DateTime.parse(t)
    end
  end


end
