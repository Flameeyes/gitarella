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

require "gitcommit"

class GITRepo
   attr_accessor :path, :description, :owner, :valid, :id

   def initialize(array)
      @id = array["id"]
      @path = array["path"]
      @description = array["description"]
      @owner = array["owner"]

      @valid = ( @id and @path and Pathname.new(@path).exist? )

      return nil unless @valid

      descfile = Pathname.new(@path + "/description")
      @description = descfile.read if not @description and descfile.exist?

      @owner = "n/a" unless @owner
   end

   def to_hash
      return unless @valid

      { "id" => @id, "path" => @path, "description" => @description,
        "owner" => @owner }
   end

   def push_gitdir
      ENV["GIT_DIR"] = "#{path}"
   end

   def sha1_head
      return unless @valid
      return @sha1_head_cache if @sha1_head_cache

      push_gitdir
      gitproc = IO.popen("git-rev-parse --verify HEAD")
      @sha1_head_cache = gitproc.read.chomp
      gitproc.close

      return @sha1_head_cache
   end

   def commit(sha1 = sha1_head)
      return GITCommit.new(self, sha1) unless not sha1 or sha1.empty?

      nil
   end
end

# kate: encoding UTF-8; remove-trailing-space on; replace-trailing-space-save on; space-indent on; indent-width 3;
