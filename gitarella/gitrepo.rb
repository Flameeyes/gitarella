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
require 'gitarella/gittag'

module Gitarella
class GITRepo
   attr_accessor :path, :description, :owner, :valid, :id, :head

   def initialize(array)
      @id = array["id"]
      @path = array["path"]
      @description = array["description"]
      @owner = array["owner"]

      @valid = ( @id and @path and Pathname.new(@path).exist? )
      Globals::log.error "path #{@path} for repository #{@id} does not exist." \
         if not valid and not Pathname.new(@path).exist?

      return nil unless @valid

      descfile = Pathname.new(@path + "/description")
      @description = descfile.read if not @description and descfile.exist?

      @owner = "n/a" unless @owner

      @head = sha1_tag("HEAD")
   end

   def push_gitdir
      ENV["GIT_DIR"] = "#{path}"
   end

   def sha1_tag(tag)
      return unless @valid
      return unless tag

      push_gitdir
      return `git rev-parse --verify #{tag}`.chomp
   end

   def commit(sha1 = @head)
      Globals::log.debug "GITRepo.commit(#{sha1})"
      return nil if not sha1 or sha1.empty?
      ret = GITCommit.get(self, sha1)
      Globals::log.debug ret
      return ret
   end

   def commits(amount, skip = 0, start = "HEAD")
      push_gitdir

      Globals::log.debug "Executing git rev-list --max-count=#{amount+skip} #{start}"

      return `git rev-list --max-count=#{amount+skip} #{start}`.split($/).slice(skip..-1).collect {
         |sha1| GITCommit.get(self, sha1)
      }
   end

   def list(path = ".", sha1 = @head)
      return Globals.cache["git-list_#{commit.tree}_#{path}"] \
         if Globals.cache["git-list_#{commit.tree}_#{path}"]

      files = Array.new

      push_gitdir
      `git ls-tree #{commit.tree} #{path}`.each_line { |line|
         linedata = line.split

         files << { "perms" => linedata[0].oct, "perms_string" => mode_str(linedata[0].oct),
         "type" => linedata[1], "sha1" => linedata[2], "name" => linedata[3].split("/")[-1] }
      }

      Globals::log.debug files.inspect

      Globals.cache["git list_#{commit.tree}_#{path}"] = files
      return files
   end

   def file(path, sha1 = nil)
      Globals::log.debug "GITRepo.file(#{path   }, #{sha1.inspect})"
      push_gitdir

      return `git cat-file blob #{sha1}` if sha1 and not sha1.empty?

      listing = list(path)[0]
      return unless listing

      return `git cat-file #{listing["type"]} #{listing["sha1"]}`
   end

   def heads
      # Don't cache this value, as we don't get any notice if the tags were
      # pushed to the repository.
      heads = Hash.new

      `git ls-remote --heads #{@path}`.split($/).collect{ |l| l.split }.each {
         |head| heads[head[1].sub("refs/heads/", "")] = head[0]
      }

      Globals::log.debug "GITRepo Heads: #{heads.inspect}"

      return heads
   end

   def tags
      # Don't cache this value, as we don't get any notice if the tags were
      # pushed to the repository.
      tags = Hash.new

      `git ls-remote --tags #{@path}`.split($/).collect{ |l| l.split }.each { |tag|
         next if tag[1] =~ /\^\{\}$/ # Ignore dereferences
         tags[tag[1].sub("refs/tags/", "")] = GITTag.get(self, tag[0])
      }

      Globals::log.debug "GITRepo Tags: #{tags.inspect}"

      return tags
   end

   def last_change
      return Time.now if not commit or not commit.commit_time

      Time.now - commit.commit_time
   end

   def to_hash
      return unless @valid

      headshashes = Array.new
      heads.each_pair { |name, head|
         headshashes << {
            "name" => name, "sha1" => head,
            "last_change" => commit(head).commit_time
            }
      }

      tagshashes = tags.values.collect { |tag| tag.to_hash }

      head = commit ? commit.to_hash : {}

      { "id" => @id, "path" => @path, "description" => @description,
        "owner" => @owner, "last_change" => last_change,
        "heads" => headshashes, "has_heads" => (not headshashes.empty?),
        "tags" => tagshashes, "has_tags" => (not tagshashes.empty?),
        "head" => head }
   end
end
end

# kate: encoding UTF-8; remove-trailing-space on; replace-trailing-space-save on; space-indent on; indent-width 3;
