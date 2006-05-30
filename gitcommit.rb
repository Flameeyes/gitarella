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

class GITCommit
   attr_accessor :author_name, :author_time, :commit_name, :commit_time,
      :description, :tree

   def initialize(repo, sha1)
      @repo = repo
      @sha1 = sha1
      repo.push_gitdir
      gitproc = IO.popen("git-rev-list --header --parents --max-count=1 #{@sha1}")
      data = gitproc.read.split("\n")
      gitproc.close

      $stderr.puts data.inspect

      verify_report = data[0].chomp; data.delete_at(0)
      @tree = data[0].split[1].chomp; data.delete_at(0)
      if data[0] =~ /^parent.*/
         @parent = data[0].split[1].chomp; data.delete_at(0)
         return nil unless verify_report == "#{@sha1} #{@parent}"
      else
         @parent = nil
         return nil unless verify_report == "#{@sha1}"
      end

      data[0] =~ /^author (.*) ([0-9]+) (\+[0-9]{4})$/
      @author_name = $1
      @author_time = Time.at($2.to_i)
      # author_tz = $3 # TODO Implement timezone diff

      data[1] =~ /^committer (.*) ([0-9]+) (\+[0-9]{4})$/
      @commit_name = $1
      @commit_time = Time.at($2.to_i)
      # committer_tz = $3 # TODO Implement timezone diff

      @description = data[3..data.size].join("\n")
   end
end

# kate: encoding UTF-8; remove-trailing-space on; replace-trailing-space-save on; space-indent on; indent-width 3;
