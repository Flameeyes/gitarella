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

class StaticOutput < Exception
end

class FileNotFound < Exception
   def message
      "Generic File Not Found exception"
   end
end

class RepositoryNotFound < FileNotFound
   def initialize(id)
      @repo_id = id
   end

   def message
      "Unable to find repository #{@repo_id}"
   end
end

class RepoFileNotFound < FileNotFound
   def initialize(repo, file)
      @repo_id = repo
      @file = file
   end

   def message
      "Unable to find '#{@file}' in repository #{@repo_id}"
   end
end

class CommitNotFound < FileNotFound
   def initialize(repo, commit)
      @repo_id = repo.is_a?(GITRepo) ? repo.id : repo
      @commit = commit
   end

   def message
      "Unable to find commit with SHA1 '#{@commit}' in repository #{@repo_id}"
   end
end

class BinaryOperationInvalid < Exception
   def message
      "Unable to perform the requested operation on a binary file."
   end
end

end


# kate: encoding UTF-8; remove-trailing-space on; replace-trailing-space-save on; space-indent on; indent-width 3;
