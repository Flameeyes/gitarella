# Gitarella - web interface for GIT
# Copyright (c) 2006 Diego "Flameeyes" Pettenò <flameeyes@gentoo.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with gitarella; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

require 'liquid'
require 'gitarella/gitutils'

module Gitarella
   module LiquidFilters
      def nl2br(input)
         input.gsub("\n", "<br />")
      end

      def date_str(input)
         Time.at(input.to_i).to_s
      end

      def age_str(input)
         return "n/a" unless input.to_i != 0
         age_string( Time.now - input.to_i )
      end

      def age_str_colored(input)
         return "n/a" unless input.to_i != 0

         str = age_string( Time.now - input.to_i )
         if (Time.now - input.to_i).to_i < 60*60*2
            return "<span style='color: #009900'><b>#{str}</b></span>"
         elsif (Time.now - input.to_i).to_i < 60*60*24*2
            return "<span style='color: #009900'>#{str}</span>"
         else
            return str
         end
      end

      def escapespecialchars(input)
         return "" unless input
         input.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
      end
   end

   class SpecialFor < Liquid::Block
      Syntax = /(\w+)\s+in\s+(#{Liquid::AllowedVariableCharacters}+)/

      def initialize(markup, tokens)
         super

         if markup =~ Syntax
            @variable_name = $1
            @collection_name = $2
         else
            raise SyntaxError.new("Syntax Error in 'specialfor loop' - Valid syntax: specialfor [item] in [collection]")
         end
      end

      def render(context)
         collection = context[@collection_name] or raise ArgumentError.new("Error in 'specialfor loop' - '#{@collection_name}' does not exist.")
         length = collection.length

         result = []

         context.stack do
            collection.each_with_index do |item, index|
               length_digits = length.to_s.size
               idx_digits = (index+1).to_s.size
               ridx_digits = (length - index).to_s.size

               alignment = ""
               while idx_digits < length_digits
                  alignment = alignment + " "
                  idx_digits += 1
               end

               ralignment = ""
               while ridx_digits < length_digits
                  ralignment = ralignment + " "
                  ridx_digits += 1
               end

               context[@variable_name] = item
               context['forloop'] = {
                  'length'  => length,
                  'aligidx' => alignment,
                  'index'   => index + 1,
                  'index0'  => index,
                  'even'    => ( ( index % 2 != 1 ) ? false : true ),
                  'rindex'  => length - index,
                  'rindex0' => length - index -1,
                  'raligidx'=> ralignment,
                  'first'   => (index == 0),
                  'last'    => (index == length - 1) }

               result << render_all(@nodelist, context)
            end
         end
         result
      end
   end

   Liquid::Template.register_filter(LiquidFilters)
   Liquid::Template.register_block('specialfor', Gitarella::SpecialFor)
end

# kate: encoding UTF-8; remove-trailing-space on; replace-trailing-space-save on; space-indent on; indent-width 3;
