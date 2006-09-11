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

class GITCommit
   attr_accessor :author_name, :author_time, :commit_name, :commit_time, :tree,
      :sha1, :description

   def GITCommit.get(repo, sha1)
      return Globals.cache["gitcommit-#{sha1}"] if Globals.cache["gitcommit-#{sha1}"]

      ret = GITCommit.new(repo, sha1)

      Globals.cache["gitcommit-#{sha1}"] = ret

      return ret
   end

   def initialize(repo, sha1)
      Globals::log.debug "GITCommit:initialize(#{repo}, #{sha1})"
      @repo = repo
      @sha1 = sha1

      repo.push_gitdir
      gitproc = IO.popen("git-rev-list --header --parents --max-count=1 #{@sha1}")
      data = gitproc.read.split("\n")
      gitproc.close

      raise CommitNotFound.new(@repo, @sha1) if data.empty?

      Globals::log.debug data.inspect

      @parents = Array.new
      verify_report = data[0].chomp; data.delete_at(0)
      @tree = data[0].split[1].chomp; data.delete_at(0)
      while data[0] =~ /^parent.*/
         @parents << data[0].split[1].chomp
         data.delete_at(0)
      end

      if @parents.size > 0
         return nil unless verify_report == "#{@sha1} #{@parents.join(" ")}"
      else
         return nil unless verify_report == "#{@sha1}"
      end

      data[0] =~ /^author (.*) <(.*)> ([0-9]+) (\+[0-9]{4})$/
      @author_name = $1
      @author_mail = $2
      @author_time = $3.to_i
      # author_tz = $4 # TODO Implement timezone diff

      data[1] =~ /^committer (.*) <(.*)> ([0-9]+) (\+[0-9]{4})$/
      @commit_name = $1
      @commit_mail = $2
      @commit_time = $3.to_i
      # commit_tz = $4 # TODO Implement timezone diff

      @description = data[3..data.size].join("\n").gsub(/\0/, '').chomp
   end

   def tags
      @repo.tags.select { |k,v| v.commit.sha1 == @sha1 } .collect { |tag| tag[0] } +
      @repo.heads.select { |k,v| v == @sha1 } .collect { |head| head[0] }
   end

   def parents
      @parents.collect { |p| @repo.commit(p) }
   end

   def short_description(size = 80)
      str_reduce(@description, size)
   end

   def changes(base = @parents[0])
      return Globals.cache["gitcommit-changes-#{sha1}_#{base}"] \
         if Globals.cache["gitcommit-changes-#{sha1}_#{base}"]
      changes = Array.new

      @repo.push_gitdir
      gitproc = IO.popen("git-diff-tree -r #{base} #{sha1}")

      gitproc.each_line { |line|
         change = Hash.new

         line =~ /^:([0-7]{6}) ([0-7]{6}) ([0-9a-f]{40}) ([0-9a-f]{40}) ([A-Z]+)[ \t]*(.*)$/
         change["old_mode"] = $1
         change["new_mode"] = $2
         change["old_hash"] = $3
         change["new_hash"] = $4
         change["flags"] = $5
         change["file"] = $6

         changes << change
      }

      Globals::log.debug changes.inspect

      gitproc.close
      Globals.cache["gitcommit-changes-#{sha1}_#{base}"] = changes
      return changes
   end

   def to_hash
      return {
         "sha1" => @sha1, "tree" => @tree, "parents_hashes" => @parents,
         "author_name" => @author_name, "author_time" => @author_time,
         "author_mail" => @author_mail,
         "commit_name" => @commit_name, "commit_time" => @commit_time,
         "commit_mail" => @commit_mail,
         "description" => description, "short_description" => short_description,
         "tags" => tags
      }
   end
end

# kate: encoding UTF-8; remove-trailing-space on; replace-trailing-space-save on; space-indent on; indent-width 3;
