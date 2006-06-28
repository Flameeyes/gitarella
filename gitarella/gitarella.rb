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

require "cgi"
require "yaml"
require "filemagic"
require "liquid"
require "pathname"

require "gitarella/exceptions"
require "gitarella/gitrepo"
require "gitarella/gitutils"
require "gitarella/project_show"
require "gitarella/tree_browse"

require "gitarella/liquid-support"

$config = YAML::load(File.new("gitarella-config.yml").read)

$memcache = nil

if $config["memcache-servers"] and not $config["memcache-servers"].empty?
   require "memcache"
   $memcache = MemCache::new($config["memcache-servers"], :namespace => 'gitarella', :compression => 'true')
   begin
      $memcache["gitarella-test"] = true
   rescue MemCache::MemCacheError
      $stderr.puts "Gitarella: memcache configured but no server available."
      $memcache = nil
   end
end

module Gitarella
   class GitarellaCGI
      attr_reader :path

      @@repos = Hash.new

      def GitarellaCGI.init_repos
         @@repos = Hash.new

         $config["repositories"].each { |repo|
            gitrepo = GITRepo.new(repo)
            @@repos[gitrepo.id] = gitrepo
         }
      end

      def initialize(cgi)
         @cgi = cgi
         @path = cgi.path_info.split(/\/+/).delete_if { |x| x.empty? } if cgi.path_info

         # Rule out the static files immediately
         static_file(".#{cgi.path_info}") if @path[0] == "static"

         @template_params = {
            "basepath" => cgi.script_name,
            "currpath" => (cgi.script_name + cgi.path_info + "/").gsub("//", "/")
         }

         @content = ""

         case path.size
            when 0 then project_list
            when 1 then project_show
            else tree_browse
         end

         @template_params["content"] = @content
         @cgi.out {
            parse_template("main")
         }
      end

      def project_list
         @template_params["repositories"] = Array.new
         @@repos.each_value { |gitrepo|
            next unless gitrepo.valid
            @template_params["repositories"] << gitrepo.to_hash
         }

         @template_params["sort"] = @cgi.has_key?("sort") ? @cgi["sort"] : "id"
         @template_params["sort"] = "id" if not @template_params["repositories"][0].has_key?(@template_params["sort"])
         @template_params["repositories"].sort! { |x, y| x[@template_params["sort"]] <=> y[@template_params["sort"]] }

         @template_params["title"] = "gitarella - browse projects"
         @content = parse_template("projects")
      end

      def static_file(path)
            staticfile = File.open(path)
            staticmime = FileMagic.new(FileMagic::MAGIC_MIME|FileMagic::MAGIC_SYMLINK).file(path)
            @cgi.out({ "content-type" => staticmime}) { staticfile.read }
            raise StaticOutput
      end

      def get_repo_id
         @repo_id = @path[0]; @path.delete_at(0)
         raise RepositoryNotFound.new(@repo_id) unless @@repos.has_key?(@repo_id)
         @repo = @@repos[@repo_id]

         @commit_hash = (@cgi.has_key?("h") and not @cgi["h"].empty?) ? @cgi["h"] : @repo.head

         @template_params["title"] = "gitarella - #{@repo_id}"
         @template_params["commit_hash"] = @commit_hash
         @template_params["commit_desc"] = @repo.commit(@commit_hash).description
         @template_params["files_list"] = @repo.list
         @template_params["repository"] = @repo.to_hash
      end

      def parse_template(name, params = @template_params)
         Liquid::Template.parse( File.open("templates/#{name}.liquid").read ).render(params)
      end
   end

   def handle(cgi)
      begin
         GitarellaCGI.new(cgi)
      rescue StaticOutput # We served a static page for whatever reason, just exit
         return
      rescue FileNotFound => err404
         cgi.out({"status" => CGI::HTTP_STATUS["NOT_FOUND"]}) { err404.message + err404.backtrace.inspect }
      rescue Exception => error
         cgi.out({"status" => CGI::HTTP_STATUS["SERVER_ERROR"]}) { error.to_s + error.backtrace.inspect}
         raise
      end
   end
end

# kate: encoding UTF-8; remove-trailing-space on; replace-trailing-space-save on; space-indent on; indent-width 3;
