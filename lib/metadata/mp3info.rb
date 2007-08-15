# $Id: mp3info.rb,v 1.4 2004/06/20 10:41:43 moumar Exp $
# = Description
#
# ruby-mp3info gives you access to low level informations on mp3 files
# (bitrate, length, samplerate, etc...). It can read, write, remove id3v1 tag
# and read id3v2. It is written in pure ruby.
#
#
# = Download
#
# get tar.gz at
# http://rubyforge.org/projects/ruby-mp3info/
#
#
# = Installation
#
#   $ ruby install.rb config
#   $ ruby install.rb setup
#   # ruby install.rb install
#
#
# = Example
#
#   require "mp3info"
#
#   mp3info = Mp3Info.new("myfile.mp3")
#   puts mp3info
#
#
# = Testing
#
# Test::Unit library is used for tests. see http://testunit.talbott.ws/
#
#  $ ruby test.rb
#
#
# = ToDo
#
# * adding write support for ID3v2 tags
# * adding a test for id3v2
# * encoder detection
#
#
# = Changelog
#
# [0.3 04/05/2004]
#
# * massive changes of most of the code to make it easier to read & hopefully run faster
# * ID2TAGS hash is just informative now, no use of it in the code. id3v2 tag fields are read in directly
# * added support for id3 v2.2 and v2.4 (0.2.1 only supported v2.3)
# * much improved vbr duration guessing
# * made Mp3Info#to_s output to be prettier
# * moved hastag1? and hastag2? to be class booleans instead of functions (now named hastag1 and hastag2)
# * fixed a bug on computing "error_protection" attribute
# * new attribute "tag", which is a sort of "universal" tag, regardless of the tag version, 1 or 2, with the same keys as @tag1
# * new method hastag?, which test the presence of any tag
#
#
# [0.2.1 04/09/2003]
# 
# * filename attribute added
# * mp3 files are opened read-only now [Alan Davies <alan__DOT_davies__AT__thomson.com>]
# * Mp3Info#initialize: bugfixes [Alan Davies <alan__DOT_davies__AT__thomson.com>]
# * put NULLs in year field in id3v1 tags instead of zeros [Alan Davies <alan__DOT_davies__AT__thomson.com>]
# * Mp3Info#gettag1: remove null at end of strings [Alan Davies <alan__DOT_davies__AT__thomson.com>]
# * Mp3Info#extract_infos_from_head(): some brackets missed [Alan Davies <alan__DOT_davies__AT__thomson.com>]
#
# 
# [0.2 18/08/2003]
#
# * writing, reading and removing of id3v1 tags
# * reading of id3v2 tags
# * test suite improved
# * to_s method added
# * length attribute is a Float now
#
#
# [0.1 17/03/2003]
#
# * Initial version
#
#
# License:: Ruby
# Author:: Guillaume Pierronnet (mailto:moumar_AT__rubyforge_DOT_org)
# Website:: http://ruby-mp3info.rubyforge.org/

# Raised on any kind of error related to ruby-mp3info
class Mp3InfoError < StandardError ; end

class Mp3InfoInternalError < StandardError #:nodoc:
end

class Numeric
  ### returns the selected bit range (b, a) as a number
  ### NOTE: b > a  if not, returns 0
  def bits(b, a)
    t = 0
    b.downto(a) { |i| t += t + self[i] }
    t
  end
end

class Hash
   ### lets you specify hash["key"] as hash.key
   ### this came from CodingInRuby on RubyGarden
   ### http://www.rubygarden.org/ruby?CodingInRuby
   def method_missing(meth,*args)
     if /=$/=~(meth=meth.id2name) then
       self[meth[0...-1]] = (args.length<2 ? args[0] : args)
     else
       self[meth]
     end
   end
end

class File
  def get32bits
    (getc << 24) + (getc << 16) + (getc << 8) + getc
  end
  def get_syncsafe
    (getc << 21) + (getc << 14) + (getc << 7) + getc
  end
end

class Mp3Info

  VERSION = "0.3"

  LAYER = [ nil, 3, 2, 1]
  BITRATE = [
    [
      [32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448],
      [32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384],
      [32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320] ],
    [
      [32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256],
      [8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160],
      [8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160]
    ]
  ]
  SAMPLERATE = [
    [ 44100, 48000, 32000 ],
    [ 22050, 24000, 16000 ]
  ]
  CHANNEL_MODE = [ "Stereo", "JStereo", "Dual Channel", "Single Channel"]

  GENRES = [
    "Blues", "Classic Rock", "Country", "Dance", "Disco", "Funk",
    "Grunge", "Hip-Hop", "Jazz", "Metal", "New Age", "Oldies",
    "Other", "Pop", "R&B", "Rap", "Reggae", "Rock",
    "Techno", "Industrial", "Alternative", "Ska", "Death Metal", "Pranks",
    "Soundtrack", "Euro-Techno", "Ambient", "Trip-Hop", "Vocal", "Jazz+Funk",
    "Fusion", "Trance", "Classical", "Instrumental", "Acid", "House",
    "Game", "Sound Clip", "Gospel", "Noise", "AlternRock", "Bass",
    "Soul", "Punk", "Space", "Meditative", "Instrumental Pop", "Instrumental Rock",
    "Ethnic", "Gothic", "Darkwave", "Techno-Industrial", "Electronic", "Pop-Folk",
    "Eurodance", "Dream", "Southern Rock", "Comedy", "Cult", "Gangsta",
    "Top 40", "Christian Rap", "Pop/Funk", "Jungle", "Native American", "Cabaret",
    "New Wave", "Psychadelic", "Rave", "Showtunes", "Trailer", "Lo-Fi",
    "Tribal", "Acid Punk", "Acid Jazz", "Polka", "Retro", "Musical",
    "Rock & Roll", "Hard Rock", "Folk", "Folk/Rock", "National Folk", "Swing",
    "Fast-Fusion", "Bebob", "Latin", "Revival", "Celtic", "Bluegrass", "Avantgarde",
    "Gothic Rock", "Progressive Rock", "Psychedelic Rock", "Symphonic Rock", "Slow Rock", "Big Band",
    "Chorus", "Easy Listening", "Acoustic", "Humour", "Speech", "Chanson",
    "Opera", "Chamber Music", "Sonata", "Symphony", "Booty Bass", "Primus",
    "Porn Groove", "Satire", "Slow Jam", "Club", "Tango", "Samba",
    "Folklore", "Ballad", "Power Ballad", "Rhythmic Soul", "Freestyle", "Duet",
    "Punk Rock", "Drum Solo", "A capella", "Euro-House", "Dance Hall",
    "Goa", "Drum & Bass", "Club House", "Hardcore", "Terror",
    "Indie", "BritPop", "NegerPunk", "Polsk Punk", "Beat",
    "Christian Gangsta", "Heavy Metal", "Black Metal", "Crossover", "Contemporary C",
    "Christian Rock", "Merengue", "Salsa", "Thrash Metal", "Anime", "JPop",
    "SynthPop" ]

  
  ID2TAGS = {
    "AENC" => "Audio encryption",
    "APIC" => "Attached picture",
    "COMM" => "Comments",
    "COMR" => "Commercial frame",
    "ENCR" => "Encryption method registration",
    "EQUA" => "Equalization",
    "ETCO" => "Event timing codes",
    "GEOB" => "General encapsulated object",
    "GRID" => "Group identification registration",
    "IPLS" => "Involved people list",
    "LINK" => "Linked information",
    "MCDI" => "Music CD identifier",
    "MLLT" => "MPEG location lookup table",
    "OWNE" => "Ownership frame",
    "PRIV" => "Private frame",
    "PCNT" => "Play counter",
    "POPM" => "Popularimeter",
    "POSS" => "Position synchronisation frame",
    "RBUF" => "Recommended buffer size",
    "RVAD" => "Relative volume adjustment",
    "RVRB" => "Reverb",
    "SYLT" => "Synchronized lyric/text",
    "SYTC" => "Synchronized tempo codes",
    "TALB" => "Album/Movie/Show title",
    "TBPM" => "BPM (beats per minute)",
    "TCOM" => "Composer",
    "TCON" => "Content type",
    "TCOP" => "Copyright message",
    "TDAT" => "Date",
    "TDLY" => "Playlist delay",
    "TENC" => "Encoded by",
    "TEXT" => "Lyricist/Text writer",
    "TFLT" => "File type",
    "TIME" => "Time",
    "TIT1" => "Content group description",
    "TIT2" => "Title/songname/content description",
    "TIT3" => "Subtitle/Description refinement",
    "TKEY" => "Initial key",
    "TLAN" => "Language(s)",
    "TLEN" => "Length",
    "TMED" => "Media type",
    "TOAL" => "Original album/movie/show title",
    "TOFN" => "Original filename",
    "TOLY" => "Original lyricist(s)/text writer(s)",
    "TOPE" => "Original artist(s)/performer(s)",
    "TORY" => "Original release year",
    "TOWN" => "File owner/licensee",
    "TPE1" => "Lead performer(s)/Soloist(s)",
    "TPE2" => "Band/orchestra/accompaniment",
    "TPE3" => "Conductor/performer refinement",
    "TPE4" => "Interpreted, remixed, or otherwise modified by",
    "TPOS" => "Part of a set",
    "TPUB" => "Publisher",
    "TRCK" => "Track number/Position in set",
    "TRDA" => "Recording dates",
    "TRSN" => "Internet radio station name",
    "TRSO" => "Internet radio station owner",
    "TSIZ" => "Size",
    "TSRC" => "ISRC (international standard recording code)",
    "TSSE" => "Software/Hardware and settings used for encoding",
    "TYER" => "Year",
    "TXXX" => "User defined text information frame",
    "UFID" => "Unique file identifier",
    "USER" => "Terms of use",
    "USLT" => "Unsychronized lyric/text transcription",
    "WCOM" => "Commercial information",
    "WCOP" => "Copyright/Legal information",
    "WOAF" => "Official audio file webpage",
    "WOAR" => "Official artist/performer webpage",
    "WOAS" => "Official audio source webpage",
    "WORS" => "Official internet radio station homepage",
    "WPAY" => "Payment",
    "WPUB" => "Publishers official webpage",
    "WXXX" => "User defined URL link frame"
  }

  TAGSIZE = 128
  #MAX_FRAME_COUNT = 6  #number of frame to read for encoder detection

  # mpeg version = 1 or 2
  attr_reader(:mpeg_version)

  # layer = 1, 2, or 3
  attr_reader(:layer)

  # bitrate in kbps
  attr_reader(:bitrate)

  # samplerate in Hz
  attr_reader(:samplerate)

  # channel mode => "Stereo", "JStereo", "Dual Channel" or "Single Channel"
  attr_reader(:channel_mode)

  # variable bitrate => true or false
  attr_reader(:vbr)

  # length in seconds as a Float
  attr_reader(:length)

  # error protection => true or false
  attr_reader(:error_protection)

  #a sort of "universal" tag, regardless of the tag version, 1 or 2, with the same keys as @tag1
  attr_reader(:tag)

  # id3v1 tag has a Hash. You can modify it, it will be written when calling
  # "close" method.
  attr_accessor(:tag1)

  # id3v2 tag as a Hash
  attr_reader(:tag2)

  # the original filename
  attr_reader(:filename)

  # Moved hastag1? and hastag2? to be booleans
  attr_reader(:hastag1, :hastag2)
  
  # Test the presence of an id3v1 tag in file +filename+
  def self.hastag1?(filename)
    File.open(filename) { |f|
      f.seek(-TAGSIZE, File::SEEK_END)
      f.read(3) == "TAG"
    }
  end

  # Test the presence of an id3v2 tag in file +filename+
  def self.hastag2?(filename)
    File.open(filename) { |f|
      f.read(3) == "ID3"
    }
  end


  # Remove id3v1 tag from +filename+
  def self.removetag1(filename)
    if self.hastag1?(filename)
      newsize = File.size(filename) - TAGSIZE
      File.open(filename, "r+") { |f| f.truncate(newsize) }
    end
  end

  # Instantiate a new Mp3Info object with name +filename+
  def initialize(filename)
    $stderr.puts("#{self.class}::new() does not take block; use #{self.class}::open() instead") if block_given?
    raise(Mp3InfoError, "empty file") unless File.stat(filename).size? #FIXME
    @filename = filename
    @hastag1, @hastag2 = false
    @tag = Hash.new
    @tag1 = Hash.new
    @tag2 = Hash.new

    @file = File.new(filename, "rb")
    parse_tags
    @tag_orig = @tag1.dup

    #creation of a sort of "universal" tag, regardless of the tag version
    if hastag2?
      h = { 
        "title"    => "TIT2",
        "artist"   => "TPE1", 
	"album"    => "TALB",
	"year"     => "TYER",
	"tracknum" => "TRCK",
	"comments" => "COMM",
	"genre"    => 255,
	"genre_s"  => "TCON"
      }

      h.each { |k, v| @tag[k] = @tag2[v] }

    elsif hastag1?
      @tag = @tag1.dup
    end


    extract_info_from_head(find_next_frame)
    seek =
    if @mpeg_version == 1                     # mpeg version 1
    (@channel_num == 3 ? 17 : 32)        # channel_num 3 = Mono
    else                                      # mpeg version 2 or 2.5
    (@channel_num == 3 ?  9 : 17)
    end
    @file.seek(seek, IO::SEEK_CUR)
    
    vbr_head = @file.read(4)
    if vbr_head == "Xing"
      @vbr = true
      parse_xing_header
    end
    if @vbr
      @length = (26/1000.0)*@frames
      @bitrate = (((@streamsize/@frames)*@samplerate)/144) >> 10
    else
      # for cbr, calculate duration with the given bitrate
      @streamsize = @file.stat.size - (@hastag1 ? TAGSIZE : 0) - (@hastag2 ? @tag2["length"] : 0)
      @length = ((@streamsize << 3)/1000.0)/@bitrate
      if @tag2["TLEN"]
        # but if another duration is given and it isn't close (within 5%)
        #  assume the mp3 is vbr and go with the given duration
        tlen = (@tag2["TLEN"].to_i)/1000
        percent_diff = ((@length.to_i-tlen)/tlen.to_f)
        if percent_diff.abs > 0.05
          # without the xing header, this is the best guess without reading
          #  every single frame
          @vbr = true
          @length = @tag2["TLEN"].to_i/1000
          @bitrate = (@streamsize / @bitrate) >> 10
        end
      end
    end
  end

  # "block version" of Mp3Info::new()
  def self.open(filename)
    m = self.new(filename)
    ret = nil
    if block_given?
      begin
        ret = yield(m)
      ensure
        m.close
      end
    else
      ret = m
    end
    ret
  end

  # Remove id3v1 from mp3
  def removetag1
    if hastag1?
      newsize = @file.stat.size(filename) - TAGSIZE
      @file.truncate(newsize)
      @tag1.clear
    end
    self
  end

  # Has file an id3v1 or v2 tag? true or false
  def hastag?
    @hastag1 or @hastag2
  end

  # Has file an id3v1 tag? true or false
  def hastag1?
    @hastag1
  end

  # Has file an id3v2 tag? true or false
  def hastag2?
    @hastag2
  end


  # Flush pending modifications to tags and close the file
  def close
    return if @file.nil?
    if @tag1 != @tag_orig
      @tag_orig.update(@tag1)
      @file.reopen(@filename, 'rb+')
      @file.seek(-TAGSIZE, File::SEEK_END)
      t = @file.read(3)
      if t != 'TAG'
        #append new tag
        @file.seek(0, File::SEEK_END)
        @file.write('TAG')
      end
      str = [
        @tag_orig["title"]||"",
        @tag_orig["artist"]||"",
        @tag_orig["album"]||"",
        ((@tag_orig["year"] != 0) ? ("%04d" % @tag_orig["year"]) : "\0\0\0\0"),
        @tag_orig["comments"]||"",
        0,
        @tag_orig["tracknum"]||0,
        @tag_orig["genre"]||255
        ].pack("Z30Z30Z30Z4Z28CCC")
      @file.write(str)
    end
    @file.close
    @file = nil
  end

  # inspect inside Mp3Info
  def to_s
    s = "MPEG #{@mpeg_version} Layer #{@layer} #{@vbr ? "VBR" : "CBR"} #{@bitrate} Kbps #{@channel_mode} #{@samplerate} Hz length #{@length} sec. error protection #{@error_protection} "
    s << "tag1: "+@tag1.inspect+"\n" if @hastag1
    s << "tag2: "+@tag2.inspect+"\n" if @hastag2
    s
  end


private

  ### parses the id3 tags of the currently open @file
  def parse_tags
    return if @file.stat.size < TAGSIZE  # file is too small
    @file.seek(0)
    f3 = @file.read(3)
    gettag1 if f3 == "TAG"  # v1 tag at beginning
    gettag2 if f3 == "ID3"  # v2 tag at beginning
    unless @hastag1         # v1 tag at end
        # this preserves the file pos if tag2 found, since gettag2 leaves
        #  the file at the best guess as to the first MPEG frame
        pos = (@hastag2 ? @file.pos : 0)
        # seek to where id3v1 tag should be
        @file.seek(-TAGSIZE, IO::SEEK_END) 
        gettag1 if @file.read(3) == "TAG"
        @file.seek(pos)
    end
  end

  ### reads in id3 field strings, stripping out non-printable chars
  ###  len (fixnum) = number of chars in field
  ### returns string
  def read_id3_string (len)
    s = String.new
    len.times do
      c = @file.getc
      # only append printable characters
      s << c if (c >= 32)
    end
    s.strip!
    return (s[0..2] == "eng" ? s[3..-1] : s)
  end
  
  ### gets id3v1 tag information from @file
  ### assumes @file is pointing to char after "TAG" id
  def gettag1
    @hastag1 = true
    @tag1["title"] = read_id3_string(30)
    @tag1["artist"] = read_id3_string(30)
    @tag1["album"] = read_id3_string(30)
    year_t = read_id3_string(4).to_i
    @tag1["year"] = year_t unless year_t == 0
    comments = @file.read(30)
    if comments[-2] == 0
      @tag1["tracknum"] = comments[-1].to_i
      comments.chop! #remove the last char
    end
    #@tag1["comments"] = comments.sub!(/\0.*$/, '')
    @tag1["comments"] = comments.strip
    @tag1["genre"] = @file.getc
    @tag1["genre_s"] = GENRES[@tag1["genre"]] || ""
  end

  ### gets id3v2 tag information from @file
  def gettag2
    @file.seek(3)
    version_maj, version_min, flags = @file.read(3).unpack("CCB4")
    unsync, ext_header, experimental, footer = (0..3).collect { |i| flags[i].chr == '1' }
    return unless [2, 3, 4].include?(version_maj)
    @hastag2 = true
    @tag2["version"] = "2.#{version_maj}.#{version_min}"
    tag2_len = @file.get_syncsafe
    if [3, 4].include?(version_maj)
      # seek past extended header if present
      @file.seek(@file.get_syncsafe - 4, IO::SEEK_CUR) if ext_header
      read_id3v2_3_frames(tag2_len)
    end
    if version_maj == 2
      read_id3v2_2_frames(tag2_len)
    end
    tag2["length"] = @file.pos
    # we should now have @file sitting at the first MPEG frame
  end

  ### runs thru @file one char at a time looking for best guess of first MPEG
  ###  frame, which should be first 0xff byte after id3v2 padding zero's
  ### returns true
  def find_v2_end
    until @file.getc == 0xff
    end
    @file.seek(-1, IO::SEEK_CUR)
    true
  end
    
  ### reads id3 ver 2.3.x/2.4.x frames and adds the contents to @tag2 hash
  ###  tag2_len (fixnum) = length of entire id3v2 data, as reported in header
  ### NOTE: the id3v2 header does not take padding zero's into consideration
  def read_id3v2_3_frames (tag2_len)
    v2end_found = false
    until v2end_found                   # there are 2 ways to end the loop
      name = @file.read(4)
      if (name[0] == 0)
        @file.seek(-4, IO::SEEK_CUR)    # 1. find a padding zero,
        v2end_found = find_v2_end       #    so we seek to end of zeros
      else
        size = @file.get32bits
        @file.seek(2, IO::SEEK_CUR)     # skip flags
        lang_encoding = @file.getc      # language encoding bit, not used now
        case name
          when /T[A-Z]+/
            @tag2[name] = read_id3_string(size-1)
          when /COMM/
            @tag2[name] = read_id3_string(size-1)
          else
            @file.seek(size-1, IO::SEEK_CUR)  
        end
        v2end_found = true if @file.pos >= tag2_len # 2. reach length from header
      end
    end
  end    

  ### reads id3 ver 2.2.x frames and adds the contents to @tag2 hash
  ###  tag2_len (fixnum) = length of entire id3v2 data, as reported in header
  ### NOTE: the id3v2 header does not take padding zero's into consideration
  def read_id3v2_2_frames (tag2_len)
    v2end_found = false
    until v2end_found
      name = @file.read(3)
      if (name[0] == 0)
        @file.seek(-3, IO::SEEK_CUR)
        v2end_found = find_v2_end
      else
        size = (@file.getc << 16) + (@file.getc << 8) + @file.getc
                # language encoding bit, not used now
        lang_encoding = @file.getc      
        data = read_id3_string(size-1)
                # Strip unnecessary "eng" from COM
        data = data[3..-1] if data[0..2] == "eng"
                # Ignore iTunes 2.x proprietary comments
        @tag2[name] = data unless (name == "COM") && (data =~ /iTun.*/)
        v2end_found = true if @file.pos >= tag2_len
      end
    end
  end    

  ### reads through @file from current pos until it finds a valid MPEG header
  ### returns the MPEG header as FixNum
  def find_next_frame
    # @file will now be sitting at the best guess for where the MPEG frame is.
    # It should be at byte 0 when there's no id3v2 tag.
    # It should be at the end of the id3v2 tag or the zero padding if there
    #   is a id3v2 tag.
    start_pos = @file.pos
    dummyproof = @file.stat.size - @file.pos
    dummyproof.times do |i|
      if @file.getc == 0xff
        head = 0xff000000 + (@file.getc << 16) + (@file.getc << 8) + @file.getc
        if check_head(head)
            return head
        else
            @file.seek(-3, IO::SEEK_CUR)
        end
      end
    end
    raise Mp3InfoError
  end

  ### checks the given header to see if it is valid
  ###  head (fixnum) = 4 byte value to test for MPEG header validity
  ### returns true if valid, false if not
  def check_head(head)
    return false if head & 0xffe00000 != 0xffe00000    # 11 bit MPEG frame sync
    return false if head & 0x00060000 == 0x00060000    #  2 bit layer type
    return false if head & 0x0000f000 == 0x0000f000    #  4 bit bitrate
    return false if head & 0x0000f000 == 0x00000000    #        free format bitstream
    return false if head & 0x00000c00 == 0x00000c00    #  2 bit frequency
    return false if head & 0xffff0000 == 0xfffe0000
    true
  end

  ### extracts MPEG info from MPEG header and stores it in the hash @mpeg
  ###  head (fixnum) = valid 4 byte MPEG header
  def extract_info_from_head(head)
    @mpeg_version = [2, 1][head[19]]
    @layer = LAYER[head.bits(18,17)]
    @bitrate = BITRATE[@mpeg_version-1][@layer-1][head.bits(15,12)-1]
    @error_protection = head[16] == 0 ? true : false
    @samplerate = SAMPLERATE[@mpeg_version-1][head.bits(11,10)]
    @padding = (head[9] == 1 ? true : false)
    @channel_mode = CHANNEL_MODE[@channel_num = head.bits(7,6)]
    @copyright = (head[3] == 1 ? true : false)
    @original = (head[2] == 1 ? true : false)
    @vbr = false
  end
  
  ### parses a XING header
  ### NOTE: assumes @file has just read in the "Xing" flag
  def parse_xing_header
    flags = @file.get32bits
    @frames = @file.get32bits if flags[1] == 1
    @streamsize = @file.get32bits if flags[2] == 1
    # currently this just skips the TOC entries if they're found
    @file.seek(100, IO::SEEK_CUR) if flags[0] == 1
    @vbr_quality = @file.get32bits if flags[3] == 1
  end
end

if $0 == __FILE__
  while filename = ARGV.shift
    begin
      info = Mp3Info.new(filename)
      puts filename
      #puts "MPEG #{info.mpeg_version} Layer #{info.layer} #{info.vbr ? "VBR" : "CBR"} #{info.bitrate} Kbps \
      #{info.channel_mode} #{info.samplerate} Hz length #{info.length} sec."
      puts info
    rescue Mp3InfoError => e
      puts "#{filename}\nERROR: #{e}"
    end
    puts
  end
end
