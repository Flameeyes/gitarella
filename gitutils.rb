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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# age_string function Copyright (c) 2005 Kay Sievers and Christian Gierke
# took from gitweb
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

# kate: encoding UTF-8; remove-trailing-space on; replace-trailing-space-save on; space-indent on; indent-width 3;
