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

require 'gitarella/gitcommit'

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
      return nil if not sha1 or sha1.empty?
      return GITCommit.new(self, sha1) unless $memcache

      $memcache["gitcommit-#{sha1}"] = GITCommit.new(self, sha1) \
         unless $memcache["gitcommit-#{sha1}"]

      return $memcache["gitcommit-#{sha1}"]
   end

   def list(path = ".", sha1 = sha1_head)
      return $memcache["git-list_#{commit.tree}_#{path}"] \
         if $memcache and $memcache["git-list_#{commit.tree}_#{path}"]

      files = Array.new

      push_gitdir
      gitproc = IO.popen("git-ls-tree #{commit.tree} #{path}")

      gitproc.each_line { |line|
         linedata = line.split

         files << { "perms" => linedata[0].oct, "perms_string" => mode_str(linedata[0].oct),
         "type" => linedata[1], "sha1" => linedata[2], "name" => linedata[3].split("/")[-1] }
      }

      $stderr.puts files.inspect

      gitproc.close

      $memcache["git-list_#{commit.tree}_#{path}"] = files if $memcache
      return files
   end

   def file(path, sha1 = nil)
      $stderr.puts "GITRepo.file(#{path   }, #{sha1.inspect})"
      push_gitdir

      if not sha1 or sha1.empty?
         listing = list(path)[0]
         return unless listing

         gitproc = IO.popen("git-cat-file #{listing["type"]} #{listing["sha1"]}")
      else
         gitproc = IO.popen("git-cat-file blob #{sha1}")
      end
      data = gitproc.read

      gitproc.close
      return data
   end

   def heads
      p = Pathname.new(@path + "/refs/heads")
      return unless p.directory?

      heads = Hash.new

      p.entries.each { |entry|
         entry = Pathname.new(@path + "/refs/heads/" + entry)
         next if entry.directory?

         heads[entry.basename] = entry.read.chomp
      }

      $stderr.puts heads.inspect

      return heads
   end

   def last_change
      return Time.now if not commit

      Time.now - commit.commit_time
   end

   def last_change_age
      return "n/a" if not commit

      age_string( Time.now - commit.commit_time )
   end

   def last_change_str
      return "n/a" if not commit

      Time.at(commit.commit_time).to_s
   end

   def to_hash
      return unless @valid

      headshashes = Array.new
      heads.each_pair{ |name, head|
         headshashes << {
            "name" => name, "sha1" => head,
            "last_change_str" => age_string( Time.now - commit(head).commit_time )
            }
      }

      { "id" => @id, "path" => @path, "description" => @description,
        "owner" => @owner, "last_change" => last_change,
        "last_change_age" => last_change_age, "last_change_str" => last_change_str,
        "heads" => headshashes }
   end
end

# kate: encoding UTF-8; remove-trailing-space on; replace-trailing-space-save on; space-indent on; indent-width 3;
