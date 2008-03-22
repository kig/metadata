was_disabled = GC.disable
require 'metadata/extract.rb'

module Metadata
  VERSION = '1.8'
end
GC.enable unless was_disabled
