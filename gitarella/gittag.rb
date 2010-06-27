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

module Gitarella
class GITTag
   attr_reader :sha1, :commit

   def GITTag.get(repo, sha1)
      return Globals.cache["gittag-#{sha1}"] if Globals.cache["gittag-#{sha1}"]

      ret = GITTag.new(repo, sha1)

      Globals.cache["gittag-#{sha1}"] = ret

      return ret
   end

   def initialize(repo, sha1)
      Globals::log.debug "GITTag:initialize(#{repo}, #{sha1})"
      @repo = repo
      @sha1 = sha1

      if @sha1.hex == 0
         @repo.push_gitdir
         @sha1 = `git rev-parse --verify #{sha1}`.chomp
      end

      repo.push_gitdir
      data = `git cat-file tag #{sha1}`.split($/)

      raise TagNotFound.new(@repo, @sha1) if data.empty?

      Globals::log.debug data.inspect

      data[0] =~ /^object ([a-f0-9]+)$/
      @commit = GITCommit.get(@repo, $1)
      raise "ouch, non commit tag?" unless data[1] == "type commit"
      data[2] =~ /^tag (.*)$/
      @name = $1
      if data[3] =~ /^tagger (.*) <(.*)> ([0-9]+) (\+[0-9]{4})$/
         @tagger_name = $1
         @tagger_mail = $2
         @tagger_time = Time.at($3.to_i)
      elsif data[3] =~ /^tagger (.*) <(.*)> *$/
         @tagger_name = $1
         @tagger_mail = $2
      end
      # tagger_tz = $4 # TODO Implement timezone diff

      @description = ""
      @gpg_signature = ""

      return unless data.index("")

      data = data.slice(data.index("")+1, data.size - data.index(""))

      if data.index("")
         description = data.slice(0, data.index("")+1)
         data = data.slice(data.index("")+1, data.size - data.index(""))
      else
         description = data
         data = []
      end
      @description = description.join("\n")
      @gpg_signature = data.join("\n")
   end

   def to_hash
      { "sha1" => @sha1, "name" => @name, "description" => @description,
        "gpg_signature" => @gpg_signature, "tagger_name" => @tagger_name,
        "tagger_mail" => @tagger_mail, "tagger_time" => @tagger_time,
        "commit" => @commit.to_hash }
   end
end
end

# kate: encoding UTF-8; remove-trailing-space on; replace-trailing-space-save on; space-indent on; indent-width 3;
