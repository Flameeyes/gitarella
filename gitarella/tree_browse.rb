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
         @content = Liquid::Template.parse( File.open("templates/tree.liquid").read ).render(@template_params)
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
            @content = Liquid::Template.parse( File.open("templates/blob.liquid").read ).render(@template_params)
         end
      end
   end
end
end

#          repo_id = path[0]; path.delete_at(0)
#          filepath = path.join('/')
#
#          unless repos.has_key?(repo_id)
#             cgi.header({"status" => CGI::NOT_FOUND})
#             return
#          end
#
#          template_params["title"] = "gitarella - #{repo_id}"
#          template_params["commit_hash"] = repos[repo_id].sha1_head
#          template_params["commit_desc"] = repos[repo_id].commit.description
#          template_params["path"] = Array.new
#
#          if repos[repo_id].list(filepath).empty?
#             cgi.out({"status" => "NOT_FOUND"}) { "File not found" }
#             return
#          elsif repos[repo_id].list(filepath)[0]["type"] == "tree"
#             prevelement = ""
#             filepath.split("/").each { |element|
#                template_params["path"] << { "path" => prevelement + "/" + element, "name" => element }
#                prevelement = element
#             }
#
#             template_params["repopath"] = "/" + filepath
#             template_params["files_list"] = repos[repo_id].list(filepath + "/")
#             content = Liquid::Template.parse( File.open("templates/tree.liquid").read ).render(template_params)
#          else
#             prevelement = ""
#             filepath.split("/").each { |element|
#                template_params["path"] << { "path" => prevelement + "/" + element, "name" => element }
#                prevelement = element
#             }
#
#             template_params["file"] = repos[repo_id].list(filepath)[0]
#             template_params["file"]["data"] = repos[repo_id].file(filepath)
#             if cgi["mode"] == "checkout" or template_params["file"]["data"] =~ /[^\x20-\x7e\s]{4,5}/
#                staticmime = FileMagic.new(FileMagic::MAGIC_MIME).buffer(template_params["file"]["data"])
#
#                cgi.out({ "content-type" => staticmime}) { template_params["file"]["data"] }
#                return
#             else
#                template_params["file"]["lines"] = template_params["file"]["data"].split("\n")
#                content = Liquid::Template.parse( File.open("templates/blob.liquid").read ).render(template_params)
#             end
#          end
#       end

# kate: encoding UTF-8; remove-trailing-space on; replace-trailing-space-save on; space-indent on; indent-width 3;
