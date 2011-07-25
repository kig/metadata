was_disabled = GC.disable
require "lib/metadata/extract.rb"

module Metadata
  VERSION = '2.0'
end
GC.enable unless was_disabled
