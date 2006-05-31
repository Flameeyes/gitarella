#!/usr/bin/env ruby
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

require "cgi"
require "yaml"
require "filemagic"
require "liquid"
require "pathname"

require "gitrepo"
require "gitutils"

config = YAML::load(File.new("gitarella-config.yml").read)

cgi = CGI.new
path = cgi.path_info.split(/\/+/).delete_if { |x| x.empty? }

# Rule out the static files immediately
if path[0] == "static"
   staticfile = File.open(".#{cgi.path_info}")
   staticmime = FileMagic.new(FileMagic::MAGIC_MIME|FileMagic::MAGIC_SYMLINK).file(".#{cgi.path_info}")

   cgi.out({ "content-type" => staticmime}) { staticfile.read }
   exit
end

template_params = { "basepath" => cgi.script_name, "currpath" => cgi.script_name + cgi.path_info }
repos = Hash.new

config["repositories"].each { |repo|
   gitrepo = GITRepo.new(repo)
   repos[gitrepo.id] = gitrepo
}

content = ""

if path.size == 0
   template_params["repositories"] = Array.new
   repos.each_pair { |id, gitrepo|
      next unless gitrepo.valid

      repo = gitrepo.to_hash
      if gitrepo.commit
         repo["last_change"] = age_string( Time.now - gitrepo.commit.commit_time)
      else
         repo["last_change"] = "never"
      end

      template_params["repositories"] << repo
   }

   template_params["title"] = "gitarella - browse projects"
   content = Liquid::Template.parse( File.open("templates/projects.liquid").read ).render(template_params)
elsif path.size == 1
   repo_id = path[0]; path.delete_at(0)
   unless repos.has_key?(repo_id)
      cgi.header({"status" => CGI::NOT_FOUND})
      exit
   end
   template_params["title"] = "gitarella - #{repo_id}"
   template_params["project_id"] = repo_id
   template_params["project_description"] = repos[repo_id].description
   template_params["commit_hash"] = repos[repo_id].sha1_head
   template_params["commit_desc"] = repos[repo_id].commit.description
   template_params["files_list"] = repos[repo_id].list

   content = Liquid::Template.parse( File.open("templates/tree.liquid").read ).render(template_params)
else
   repo_id = path[0]; path.delete_at(0)
   filepath = path.join('/')

   unless repos.has_key?(repo_id)
      cgi.header({"status" => CGI::NOT_FOUND})
      exit
   end

   template_params["title"] = "gitarella - #{repo_id}"
   template_params["project_id"] = repo_id
   template_params["project_description"] = repos[repo_id].description
   template_params["commit_hash"] = repos[repo_id].sha1_head
   template_params["commit_desc"] = repos[repo_id].commit.description
   template_params["path"] = Array.new

   if repos[repo_id].list(filepath).empty?
      cgi.out({"status" => "NOT_FOUND"}) { "File not found" }
      exit
   elsif repos[repo_id].list(filepath)[0]["type"] == "tree"
      prevelement = ""
      filepath.split("/").each { |element|
         template_params["path"] << { "path" => prevelement + "/" + element, "name" => element }
         prevelement = element
      }

      template_params["repopath"] = "/" + filepath
      template_params["files_list"] = repos[repo_id].list(filepath + "/")
      content = Liquid::Template.parse( File.open("templates/tree.liquid").read ).render(template_params)
   else
      prevelement = ""
      filepath.split("/").each { |element|
         template_params["path"] << { "path" => prevelement + "/" + element, "name" => element }
         prevelement = element
      }

      template_params["file"] = repos[repo_id].list(filepath)[0]
      template_params["file"]["data"] = repos[repo_id].file(filepath)
      if cgi["mode"] == "checkout" or template_params["file"]["data"] =~ /[^\x20-\x7e\s]{4,5}/
         staticmime = FileMagic.new(FileMagic::MAGIC_MIME).buffer(template_params["file"]["data"])

         cgi.out({ "content-type" => staticmime}) { template_params["file"]["data"] }
         exit
      else
         template_params["file"]["lines"] = template_params["file"]["data"].split("\n")
         content = Liquid::Template.parse( File.open("templates/blob.liquid").read ).render(template_params)
      end
   end
end

cgi.out {
   Liquid::Template.parse( File.open("templates/main.liquid").read ).render(template_params.merge({ "content" => content }))
}

# kate: encoding UTF-8; remove-trailing-space on; replace-trailing-space-save on; space-indent on; indent-width 3;
