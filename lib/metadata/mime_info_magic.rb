#
# $Id: mime_info_magic.rb 4 2004-06-19 18:59:33Z tilman $
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

class MimeInfoMagicEntry
	attr_accessor :type, :priority, :rules

	def initialize(type, priority)
		@type = type
		@priority = priority
		@rules = []
	end
end

class MimeInfoMagicRule
	attr_accessor :indent, :offset, :val_len, :value,
	              :mask, :wsize, :range

	def initialize()
		@indent = 0
		@range = 1
		@wsize = 1
	end
end

class MimeInfoMagic
	include Singleton

	def init(dirs)
		@magic = {}
		@max_extents = 0

		dirs.each do |dir|
			file = dir + "/mime/magic"

			if File.file?(file)
				read_magic(file)
			end
		end
	end

public
	def type(file, priority=[80, 2 ** 32])
		return nil if @magic.empty?
		return nil if (!File.file?(file)) || !(f = File.new(file))
		return nil if !(data = f.read(@max_extents))

		@magic.each do |mime, entry|
			if priority && !priority.empty?
				next if entry.priority < priority[0] ||
				        entry.priority > priority[1]
			end

			# check all rules against the file
			return mime if check_magic_entry(entry, data)
		end

		return nil
	end

private
	def read_magic(file)
		f = File.new(file)
		return if f.read(12) != "MIME-Magic\0\n"

		@max_extents = 0

		while buf = f.gets
			# check for new mimetype
			if buf =~ /^\[(\d+):(.*)\]$/
				last_entry = MimeInfoMagicEntry.new($2, $1.to_i)
				@magic[$2] = last_entry
				next
			elsif !(buf =~ /^(\d*)>(\d+)=(.).*$/)
				next
			end

			rule = MimeInfoMagicRule.new
			rule.indent = $1.to_i
			rule.offset = $2.to_i

			offs = $~.offset(3)[0]

			# read value length
			rule.val_len = buf.unpack("@#{offs}n")[0]
			offs += 2

			# read word size and range
			buf =~ /.{#{offs + rule.val_len}}~*(\d*)\+*(\d*)$/
			rule.wsize = (!$1 || $1.empty?) ? 1 : $1.to_i

			rule.range = (!$2 || $2.empty?) ? 1 : $2.to_i

			# read value
			fmt = ["C", "n", "", "N"][rule.wsize - 1].to_s
			rule.value = buf.unpack("@#{offs}#{fmt}#{rule.val_len}")
			offs += rule.val_len

			# read mask
			if buf[offs, 1] == "&"
				rule.mask = buf.unpack("@#{offs}#{fmt}#{rule.val_len}")
			end

			ex = rule.val_len + rule.offset + rule.range
			@max_extents = ex unless @max_extents > ex

			last_entry.rules << rule
		end
	end

	def check_magic_entry(entry, data)
		return compare_indent(entry, data, 0, 0)
	end

	def compare_indent(entry, data, rule_no, indent)
		rule = entry.rules.at(rule_no)
		return false unless rule

		while rule && rule.indent == indent
			if compare_data(rule, data)
				r = entry.rules.at(rule_no + 1)
				return true if (!r || r.indent <= indent) ||
				               compare_indent(entry, data,
				                              rule_no + 1, indent + 1)
			end

			begin
				rule_no += 1
				rule = entry.rules.at(rule_no)
			end while rule && rule.indent > indent
		end

		return false
	end

	def compare_data(rule, data)
		if rule.offset > data.length or
		   rule.offset + rule.value.size > data.length
			return false
		end
		fmt = ["C", "n", "", "N"][rule.wsize - 1].to_s
		value = data.unpack(
			"@#{rule.offset}#{fmt}#{rule.value.size+rule.range-1}")
		while start = value.index(rule.value.first)
			return true if value[0, rule.value.size] == rule.value
			value = value[start+1..-1]
		end
		return false
	end
end
