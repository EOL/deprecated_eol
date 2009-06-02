# $Id: columnize.rb 12 2007-12-09 16:49:46Z rockyb $
# 
#   Copyright (C) 2007 Rocky Bernstein <rockyb@rubyforge.net>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
#    02110-1301 USA.
#

# Author::    Rocky Bernstein  (mailto:rockyb@rubyforge.net)
#
# Display a list of strings as a compact set of columns.
#
# Each column is only as wide as necessary.
# By default, columns are separated by two spaces (one was not legible enough).
# Adapted from the routine of the same name in cmd.py

module Columnize

  # Return a string with embedded newlines (\n) arranging +list+ in 
  # column-order so that each line is no larger than +displaywidth+.
  # If +list+ is not an array, the empty string, '', is returned.
  # +colsep+ contains the string to use to separate entries.
  def columnize(list, displaywidth=80, colsep = '  ')
    if not list.is_a?(Array)
      return ''
    end
    if list.size == 0
      return  "<empty>\n"
    end
    l = list.map{|l| l.to_s}
    if 1 == l.size
      return "#{l[0]}\n"
    end
    # Consider arranging list in 1 rows total, then 2 rows...
    # Stop when at the smallest number of rows which
    # can be arranged less than the display width.
    nrows = ncols = 0
    colwidths = []
    1.upto(l.size) do 
      colwidths = []
      nrows += 1
      
      ncols = (l.size + nrows-1) / nrows
      totwidth = -colsep.length
      0.upto(ncols-1) do |col|
        # get max column width for this column
        colwidth = 0
        0.upto(nrows-1) do |row|
          i = row + nrows*col  # [rows, cols]
          if i >= l.size
            break
          end
          colwidth = [colwidth, l[i].size].max
        end
        colwidths << colwidth
        totwidth += colwidth + colsep.length
        if totwidth > displaywidth
          break
        end
      end
      if totwidth <= displaywidth
        break
      end
    end
    # The smallest number of rows computed and the
    # max widths for each column has been obtained.
    # Now we just have to format each of the
    # rows.
    s = ''
    0.upto(nrows-1) do |row| 
      texts = []
      0.upto(ncols-1) do |col|
        i = row + nrows*col
        if i >= l.size
          x = ""
        else
          x = l[i]
      end
      texts << x
      end
      while texts and texts[-1] == ''
      texts = texts[0..-2]
      end
      0.upto(texts.size-1) do |col|
        texts[col] = texts[col].ljust(colwidths[col])
      end
      s += "%s\n" % texts.join(colsep)
    end
    return s
  end
  module_function :columnize
end
if __FILE__ == $0 or
    ($DEBUG and ['rdebug', 'rcov'].include?(File.basename($0)))
  #
  puts Columnize::columnize(5)
  include Columnize
  puts columnize([])
  puts columnize(["a", 2, "c"], 10, ', ')
  puts columnize(["oneitem"])
  puts columnize(["one", "two", "three"])
  puts columnize([
                  "one", "two", "three",
                  "4ne", "5wo", "6hree",
                  "7ne", "8wo", "9hree",
                  "10e", "11o", "12ree",
                  "13e", "14o", "15ree",
                  "16e", "17o", "18ree",
                  "19e", "20o", "21ree",
                  "22e", "23o", "24ree",
                  "25e", "26o", "27ree",
                  "28e", "29o", "30ree",
                  "31e", "32o", "33ree",
                  "34e", "35o", "36ree",
                  "37e", "38o", "39ree",
                  "40e", "41o", "42ree",
                  "43e", "44o", "45ree",
                  "46e", "47o", "48ree",
                  "one", "two", "three"])
end
