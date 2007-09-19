require 'sha1'

class Hash
  def bencode
    "d"+map{|k,v| k.bencode+v.bencode}.join+"e"
  end
end

class Array
  def bencode
    "l"+map{|i| i.bencode}.join+"e"
  end
  
  def expand_bdecoded
    case k=shift
    when :d
      vs = []
      map{|x|
        if x.is_a? Array
          vs << x.expand_bdecoded
        else
          vs << x
        end
      }
      Hash[*vs]
    when :l
      map{|x|
        if x.is_a? Array
          x.expand_bdecoded
        else
          x
        end
      }
    when Array
      k.expand_bdecoded
    else
      k
    end
  end
end

class Numeric
  def bencode
    "i#{self}e"
  end
end

class String
  def bencode
    "#{size}:#{self}"
  end

  def bdecode
    w = clone
    stack = [[]]
    until w.empty?
      k=w.slice!(0,1)
      case k
      when 'i'
        stack.push w.slice!(0...w.index("e")).to_i
      when 'd'
        stack.push [:d]
      when 'l'
        stack.push [:l]
      when 'e'
        c = stack.pop
        stack.last.push(c)
      else
        len = (k+w.slice!(0..w.index(":")).chop!).to_i
        stack.last.push(w.slice!(0,len))
      end
    end
    stack.expand_bdecoded
  end
end

class Symbol
  def bencode
    to_s.bencode
  end
end

def create_pieces(filename, piece_length)
  pieces = ""
  File.open(filename){|f|
    pieces << SHA1.sha1(f.read(piece_length)).digest until f.eof?
  }
  pieces
end

def create_metainfo(announce, filenames, dirname=".", piece_length=2**18)
  piece_length = piece_length.to_i
  info = {
      :name => dirname.to_s,
      "piece length" => piece_length
  }
  if filenames.is_a? Array
    pieces = ""
    info[:files] = filenames.map{|fn|
      pieces << create_pieces(fn, piece_length)
      {:path => fn.split("/"), :length => File.size(fn)}
    }
  else
    info[:length] = File.size(filenames)
    pieces = create_pieces(filenames, piece_length)
  end
  info[:pieces] = pieces
  {
    :announce => announce.to_s,
    :info => info
  }.bencode
end

