################################################################################
#
# Copyright (C) 2006 Peter J Jones (pjones@pmade.com)
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
################################################################################
class PDF::Reader
  ################################################################################
  class XRef
    ################################################################################
    def initialize (buffer)
      @buffer = buffer
      @xref = {}
    end
    ################################################################################
    def load (offset = nil)
      @buffer.seek(offset || @buffer.find_first_xref_offset)
      token = @buffer.token

      if token == "xref"
        load_xref_table
      end
    end
    ################################################################################
    def object (ref, save_pos = true)
      pos = @buffer.pos if save_pos
      parser = Parser.new(@buffer.seek(offset_for(ref)), self).object(ref.id, ref.gen)
      @buffer.seek(pos) if save_pos
      parser
    end
    ################################################################################
    def load_xref_table
      objid, count = @buffer.token.to_i, @buffer.token.to_i

      count.times do
        offset = @buffer.token.to_i
        generation = @buffer.token.to_i
        state = @buffer.token

        store(objid, generation, offset) if state == "n"
        objid += 1
      end

      raise "PDF malformed, missing trailer after cross reference" unless @buffer.token == "trailer"
      raise "PDF malformed, trailer should be a dictionary" unless @buffer.token == "<<"

      trailer = Parser.new(@buffer, self).dictionary
      load(trailer['Prev']) if trailer.has_key?('Prev')

      trailer
    end
    ################################################################################
    def offset_for (ref)
      @xref[ref.id][ref.gen]
    end
    ################################################################################
    def store (id, gen, offset)
      (@xref[id] ||= {})[gen] ||= offset
    end
    ################################################################################
  end
  ################################################################################
end
################################################################################
