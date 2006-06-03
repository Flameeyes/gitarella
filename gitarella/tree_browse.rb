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

module Gitarella
class GitarellaCGI
   def tree_browse
      get_repo_id

      @filepath = @path.join('/')
      raise RepoFileNotFound.new(@repo_id, @filepath) if @repo.list(@filepath).empty?

      @template_params["path"] = Array.new

      if @repo.list(@filepath)[0]["type"] == "tree"
         prev_element = ""
         @path.each { |element|
            @template_params["path"] << { "path" => prev_element + "/" + element, "name" => element }
            prev_element = element
         }

         @template_params["repopath"] = "/" + @filepath
         @template_params["files_list"] = @repo.list(@filepath + "/")
         @content = parse_template("tree")
      else
         prev_element = ""
         @filepath.each { |element|
            @template_params["path"] << { "path" => prev_element + "/" + element, "name" => element }
            prev_element = element
         }

         @template_params["file"] = @repo.list(@filepath)[0]
         @template_params["file"]["data"] = @repo.file(@filepath)

         if @cgi["mode"] == "checkout" or @template_params["file"]["data"] =~ /[^\x20-\x7e\s]{4,5}/
            staticmime = FileMagic.new(FileMagic::MAGIC_MIME).buffer(@template_params["file"]["data"])

            @cgi.out({ "content-type" => staticmime}) { @template_params["file"]["data"] }
            raise StaticOutput
         else
            @template_params["file"]["lines"] = @template_params["file"]["data"].split("\n")
            @content = parse_template("blob")
         end
      end
   end
end
end

# kate: encoding UTF-8; remove-trailing-space on; replace-trailing-space-save on; space-indent on; indent-width 3;
