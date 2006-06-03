#!/usr/bin/env ruby
# Gitarella - web interface for GIT
# Copyright (c) 2006 Diego "Flameeyes" Pettenò <flameeyes@gentoo.org>
# CGI/FastCGI bridge inspired by gorg, Copyright (C) 2004-2006 Xavier Neys
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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

require 'cgi'
require 'fcgi'

# Overload read_from_cmdline to avoid crashing when request method
# is neither GET/HEAD/POST. Default behaviour is to read input from
# STDIN. Not really useful when your webserver gets OPTIONS / :-(
class CGI
   module QueryExtension
      def read_from_cmdline
         ''
      end
   end
end

require 'gitarella/gitarella'

STDERR.close

#$stderr = File.new("/tmp/gitarella.log", "w")
#$stderr.puts "Uhm"

countReq = 0; t0 = Time.new
# Process CGI requests sent by the fastCGI engine
FCGI.each_cgi do |cgi|
   countReq += 1
   #$stderr.puts "Handling request.."
   handle_request(cgi)
   #$stderr.puts "Handled request.."

   # Garbage Collect regularly to help keep memory
   # footprint low enough without costing too much time.
   GC.start if countReq%50==0
end

# kate: encoding UTF-8; remove-trailing-space on; replace-trailing-space-save on; space-indent on; indent-width 3;
