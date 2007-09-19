#
# $Id: mime_info.rb 4 2004-06-19 18:59:33Z tilman $
#
# Copyright (C) 2004 Tilman Sauerbeck (tilman at code-monkey de)
#                    Ilmari Heikkinen (kig at misfiring net)
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

require "singleton"
require "rexml/document"
require "metadata/mime_info_magic"


=begin
 MimeInfo class provides an interface to query freedesktop.org's
 shared-mime-info database. It can be used to guess a filename's
 Mimetype and to get the description for the Mimetype.

   info = MimeInfo.get('foo.xml') #=> Mimetype['text/xml']
   info.description #=> "eXtensible Markup Language document"
   info.description("de") #=> "XML-Dokument"
  
   info2 = MimeInfo.get('foo.rb') #=> Mimetype['application/x-ruby']
   info2.description #=> "Ruby script"
   info2.is_a? Mimetype['text/plain'] #=> true

 See also Mimetype documentation.
=end
class MimeInfo

  include Singleton

  attr_reader :globs, :globs_ext, :type_exts

  def initialize
    @globs_ext = {}
    @type_exts = {}
    @globs = {}

    dirs = get_mime_dirs

    dirs.each do |dir|
      file = dir + "/mime/globs"
      if File.file?(file)
        read_globs(file)
      end
    end

    @magic = MimeInfoMagic.instance
    @magic.init(dirs)
  end

  # Get mimetype for filename.
  #
  def self.get(filename)
    instance.type(filename)
  end
  
  class << self
    alias_method :[], :get
  end

public
  # Runs @checks against the given filename.
  def type(filename)
    rv = special_node_type(filename)
    return Mimetype[rv] if rv
    mrv = default_magic_type(filename)
    return Mimetype[mrv] if mrv
    # okay, let's guess.
    lmrv = lesser_magic_type(filename)
    nrv = type_for_name(filename)
    brv = text_or_binary(filename)
    rv = (nrv || lmrv || brv)
    if File.exist?(filename)
      ft = Metadata.secure_filename(filename){|tfn|
        `file -ib #{tfn}`.strip
      }
      # if ft and nrv disagree, use lmrv || nrv || ft
      if nrv and ft != nrv
        if generic_type?(lmrv)
          rv = nrv || lmrv || ft
        else
          rv = lmrv || nrv || ft
        end
      end
    end
    return nil unless rv
    Mimetype[ rv ]
  end

  GENERIC_TYPES = %w(
    application/x-ole-storage
    application/zip
    application/xml
    text/x-csrc
    application/x-gzip
    application/x-tar
    application/x-bzip
    application/x-compressed-tar
    application/x-bzip-compressed-tar
    image/tiff
    video/x-theora+ogg
    audio/x-vorbis+ogg
    audio/mpeg
    video/x-ms-asf
  )

  def generic_type?(t)
    GENERIC_TYPES.include?(t)
  end

  # check if we are dealing with a special node
  def special_node_type(filename)
    stat = File.stat(filename)
    case
    when stat.blockdev?
      "inode/blockdevice"
    when stat.chardev?
      "inode/chardevice"
    when stat.directory?
      "inode/directory"
    when stat.pipe?
      "inode/fifo"
    when stat.socket?
      "inode/socket"
    when stat.symlink?
      "inode/symlink"
    when (not stat.file?)
      "inode/door"
    else
      nil
    end
  rescue IOError, SystemCallError
    type_for_name(filename)
  end

  # perform magic checks w/ the default priority
  def default_magic_type(filename)
    @magic.type(filename)
  end

  # do glob check for filename
  def type_for_name(filename)
    basename = File.basename(filename)
    [basename, basename.downcase].each do |f|
      # check whether @globs has an entry for this file
      @globs.each { |k, v| return v if File.fnmatch(k, f) }

      # no luck. try again with @globs_ext
      parts = f.to_s.split(".")
      v = nil
      (1...parts.size).find{|i|
        v = @globs_ext["." + parts[i..-1].join(".")]
      }
      return v if v
    end
    return 'inode/directory' if filename[-1,File::SEPARATOR.size] == File::SEPARATOR
    nil
  end

  # check the file against the remaining magic rules
  def lesser_magic_type(filename)
    @magic.type(filename, [0, 79])
  end

  # fallback to a simple way of determining whether it's
  # a text file or a binary
  def text_or_binary(filename)
    type = "text/plain"
    stat = File.stat(filename)
    File.open(filename) {|f|
      # check the first 32 bytes for ASCII control characters
      data = f.read((stat.size < 32) ? stat.size : 32)
      data.each_byte do |b|
        if b < 32 && b != 9 && b != 10 && b != 13
          type = "application/octet-stream"
          break
        end
      end
    }
    type
  rescue IOError, SystemCallError
    nil
  end

  def description(mime, language=nil)
    Mimetype[mime].description(language)
  end
  
  def self.description(*args)
    instance.description(*args)
  end

  # Loads [descriptions_hash, superclasses_array] -pair
  # for mimetype string.
  #
  def load_info(mimetype)
    files = get_mime_dirs.map{|dir|
      File.join(dir, 'mime', "#{mimetype}.xml")
    }.find_all{|file| File.file? file }
    descriptions = {}
    superclasses = []
    files.each{|file|
      File.open(file) do |f|
        doc = REXML::Document.new(f)
        doc.elements.each('mime-type/comment'){|com|
          descriptions[com.attributes['xml:lang']] ||= com.text
        }
        doc.elements.each('mime-type/sub-class-of'){|sc|
          superclasses << sc.attributes['type']
        }
      end
    }
    [descriptions, superclasses.compact]
  end

  def get_mime_dirs
    dirs = []

    if s = ENV["XDG_DATA_DIRS"] && tmp = s.split(":")
      # strip trailing slashes, then append to the array
      tmp.each { |t| dirs << t.gsub(/\/*$/, "") }
    end

    # add default data directories
    if dirs.empty?
      dirs << "/usr/share" << "/usr/local/share"
    end

    count = dirs.length

    if s = ENV["XDG_DATA_HOME"] && tmp = s.split(":")
      # strip trailing slashes, then append to the array
      tmp.each { |t| dirs << t.gsub(/\/*$/, "") }
    end

    # add default directory
    if dirs.length == count && s = ENV["HOME"]
      dirs << s + "/.local/share"
    end

    return dirs
  end

private
  def read_globs(file)
    IO.foreach(file) do |line|
      line.strip!

      if line =~ /^#/ || line =~ /^$/
        next # ignore comments and empty lines
      end

      # extract mime type and pattern
      token = line.split(":")

      # check whether pattern is of the form *.extension
      if /^\*\.[^\*\?\[]*$/ =~ token[1]
        # store these in a separate hash
        ext = token[1][1..-1]
        @globs_ext[ext] = token[0]
        (@type_exts[token[0]] ||= []) << ext
      else
        @globs[token[1]] = token[0]
      end
    end
  end

end


=begin
 Mimetype module for modelling the MIME type class hierarchy.
 Can be used to query MIME type descriptions and subclassing.

   t = Mimetype['audio/x-mp3'] #=> Mimetype['audio/x-mp3']
   t.description #=> "MP3 audio"
   t.description('cy') #=> "Sain MP3"
   t.descriptions['fr'] #=> "audio MP3"
   t == Mimetype['audio']['x-mp3'] #=> true
   t.is_a? Mimetype['audio'] #=> true
   t.ancestors #=> [Mimetype['audio/x-mp3'], Mimetype['audio'],
               #    Mimetype['application/octet-stream'], Mimetype,
               #    Module, Object, Kernel]

 See also MimeInfo documentation for querying type of files.
=end
module Mimetype

  attr_accessor :mimetype, :mimetypes
        attr_writer   :descriptions
  
  # Returns the Mimetype corresponding to type_name.
  #
  def [](type_name, full_name=type_name)
    @mimetypes ||= {}
    @mimetypes[type_name] ||= create_subtype(type_name, full_name)
  end

  # Creates a subtype tree from a type_name.
  # Mimetype['application/pdf'] == Mimetype['application']['pdf']
  #
  def create_subtype(type_name, full_name=type_name)
    types = split_type(type_name)
    if types.size > 1
      self[ types[0] ][ types[1..-1].join("/"), full_name ]
    else
      if not full_name.include?("/") and not mimetype.nil?
        full_name = [mimetype, full_name].join("/")
      end
      c = Module.new
      parent = self
      c.instance_eval{
        extend(Mimetype)
        @mimetype = full_name
        @mimetypes = {}
        mixin_superclasses(parent)
      }
      c
    end
  end

  # Mixes in the super"classes".
  #
  def mixin_superclasses(parent)
    if @mimetype != 'application' and
       @mimetype != 'application/octet-stream' and
       @mimetype.split("/").first != 'inode'
      extend(Mimetype['application/octet-stream'])
    end
    extend(parent)
    if @mimetype != 'text' and
       @mimetype != 'text/plain' and
       @mimetype.split("/").first == 'text'
      extend(Mimetype['text/plain'])
    end
  end
  private(:mixin_superclasses)

  # Splits type_name into a [MEDIA, SUBTYPE]-array.
  #
  def split_type(type_name)
    type_name.split("/")
  end

  # Looks up description for @mimetype in given language.
  #
  def description(language=nil)
    self.descriptions[language]
  end
  
  def extname
    extnames[0]
  end

  def extnames
    MimeInfo.instance.type_exts[@mimetype] || [""]
  end
  
  # Returns the descriptions hash for @mimetype.
  # Loads descriptions if they aren't loaded.
  #
  def descriptions
    load_info unless @sub_class_of
    @descriptions
  end

  # Returns the superclasses array for @mimetype.
  # I.e. _explicit_ sub-class-of types for the mimetype.
  # Use #ancestors instead of this if you need the
  # implicit superclasses aswell.
  #
  # Loads superclasses if they aren't loaded.
  #
  def sub_class_of
    load_info unless @sub_class_of
    @sub_class_of
  end
  
  # Loads descriptions and superclass -info for @mimetype.
  #
  def load_info
    @descriptions, @sub_class_of = *MimeInfo.instance.load_info(@mimetype)
    @sub_class_of.each{|sc|
      extend Mimetype[sc]
    }
    extend(self)
    true
  end
  
  # Returns mimetype string
  #
  def to_s
    @mimetype.to_s
  end
  
  # Returns "Mimetype" for the root class,
  # "Mimetype['#{to_s}']" for others.
  #
  def inspect
    "Mimetype#{"['#{to_s}']" if @mimetype}"
  end
  
  # Singleton class ancestors;
  # the Mimetypes this one inherits.
  # Loads info unless loaded
  #
  def ancestors
    load_info unless @sub_class_of
    class<<self; ancestors end
  end
  
  # Returns true if mimetype is
  # this one's ancestor.
  # Loads info unless loaded.
  #
  def is_a?(mimetype)
    load_info unless @sub_class_of
    super
  end

  extend self

end


if __FILE__ == $0

  if file = ARGV[0]
  
    print "looking up mimetype for #{file}... "
  
    if m = MimeInfo.get(file)
      puts m
    else
      puts "no match :("
    end

  else

    require 'test/unit'


    class MimeTest < Test::Unit::TestCase

      def setup
        @info = MimeInfo.get('foo.xml')
        @t = Mimetype['audio/x-mp3']
      end
  
      def test_info
        assert_equal(Mimetype['text/xml'], @info)
        assert_equal("eXtensible Markup Language document", @info.description)
        assert_equal("XML-Dokument", @info.description("de"))
      end

      def test_extensions
        assert_equal(nil, MimeInfo.get("foo.ext"))
        assert_equal(Mimetype['application/pdf'], MimeInfo.get("foo.pdf"))
        assert_equal(Mimetype['inode/directory'], MimeInfo.get("foo"+File::SEPARATOR))
      end
  
      def test_files
        assert_equal(Mimetype['inode/directory'], MimeInfo.get("."))
        assert_equal(Mimetype['application/x-ruby'], MimeInfo.get("mime_info.rb"))
      end
  
      def test_Mimetype
        assert_equal(@t, Mimetype['audio/x-mp3'])
        assert_equal(@t.description, "MP3 audio")
        assert_equal(@t.description('cy'), "Sain MP3")
        assert_equal(@t.descriptions['fr'], "audio MP3")
        assert_equal(@t, Mimetype['audio']['x-mp3'])
        assert(@t.is_a?(Mimetype['audio']))
        assert_equal(@t.ancestors,
                     [Mimetype['audio/x-mp3'], Mimetype['audio'], Mimetype['application/octet-stream']] +
                     Mimetype.ancestors)
      end
  
      def test_sub_class_of
        assert(Mimetype['application/x-ruby'].is_a?(Mimetype['text/plain']))
        assert(Mimetype['application/x-python'].is_a?(Mimetype['text/plain']))
        assert(Mimetype['text/plain'].is_a?(Mimetype['text/plain']))
        assert(Mimetype['text/xml'].is_a?(Mimetype['text/plain']))
        assert(!Mimetype['image/jpeg'].is_a?(Mimetype['text/plain']))
        assert(!Mimetype['inode/directory'].is_a?(Mimetype['application/octet-stream']))
        assert(Mimetype['image/jpeg'].is_a?(Mimetype['image']))
        assert(Mimetype['inode/mount-point'].is_a?(Mimetype['inode/directory']))
      end

    end


  end

end
