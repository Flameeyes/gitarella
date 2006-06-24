# Gitarella - web interface for GIT
# Copyright (c) 2006 Diego "Flameeyes" Pettenò <flameeyes@gentoo.org>
# Portions copyright (c) 2005 Kay Sievers and Christian Gierke
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

# age_string function took from gitweb
def age_string(age)
   if age > 60*60*24*365*2
      return "#{(age/(60*60*24*365)).to_i} years ago"
   elsif age > 60*60*24*(365/12)*2
      return "#{(age/(60*60*24*(365/12))).to_i} months ago"
   elsif age > 60*60*24*7*2
      return "#{(age/(60*60*24*7)).to_i} weeks ago"
   elsif age > 60*60*24*2
      return "#{(age/(60*60*24)).to_i} days ago"
   elsif age > 60*60*2
      return "#{(age/(60*60)).to_i} hours ago"
   elsif age > 60*2
      return "#{(age/60).to_i} mins ago"
   elsif age > 2
      return "#{(age).to_i} secs ago"
   else
      return "right now"
   end
end

# mode_str function took from gitweb
def mode_str(mode)
   vS_IFMT = 0170000
   vS_IFDIR = 040000
   vS_IFLNK = 0120000
   vS_IFREG = 0100000
   vS_IXUSR = 0100

   if mode&vS_IFMT == vS_IFDIR
      return 'drwxr-xr-x'
   elsif mode == vS_IFLNK
      return 'lrwxrwxrwx'
   elsif mode&vS_IFMT == vS_IFREG
      if mode & vS_IXUSR
         return '-rwxr-xr-x'
      else
         return '-rw-r--r--'
      end
   else
      return '----------'
   end
end

# originally chop_str in gitweb
def str_reduce(str, len)
   str =~ /^(.{0,#{len}}[^ \/\-_:\.@]{0,5})(.*)/
   body = $1
   tail = $2
   tail = "..." if tail and tail.size > 4

   "#{body}#{tail}"
end

# kate: encoding UTF-8; remove-trailing-space on; replace-trailing-space-save on; space-indent on; indent-width 3;
