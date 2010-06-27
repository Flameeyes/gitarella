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
require "liquid"
require "pathname"
require 'rack/request'
require 'rack/response'

require "gitarella/support"
require "gitarella/exceptions"
require "gitarella/gitrepo"
require "gitarella/gitutils"
require "gitarella/project_show"
require "gitarella/tree_browse"
require "gitarella/globals"
require "gitarella/liquid-support"

module Gitarella
  class GitarellaCGI
    attr_reader :path, :request, :response

    def initialize
      Globals::init_all unless Globals::initialised
      @template_params = {}
    end

    def params
      @params ||= request.params
    end

    def project_list
      @template_params["repositories"] = Array.new
      Globals::repos.each_value { |gitrepo|
        next unless gitrepo.valid
        @template_params["repositories"] << gitrepo.to_hash
      }

      @template_params["sort"] = params["sort"] || "id"
      @template_params["sort"] = "id" if not @template_params["repositories"][0].has_key?(@template_params["sort"])
      @template_params["repositories"].sort! { |x, y| x[@template_params["sort"]] <=> y[@template_params["sort"]] }

      @template_params["title"] = "#{Globals::config["title"]} - browse projects"
      @content = parse_template("projects")
    end

    def static_file(path)
      staticfile = File.open(path)
      begin
        require "filemagic"
        staticmime = FileMagic.new(FileMagic::MAGIC_MIME|FileMagic::MAGIC_SYMLINK).file(path)
      rescue LoadError
        Globals::log.error "unable to load 'filemagic' extension, mime support will be disabled."
        staticmime = "application/octet-stream"
      end

      response["content-type"] = staticmime
      response.write staticfile.read
      raise StaticOutput
    end

    def get_repo_id
      @repo_id = @path[0]; @path.delete_at(0)
      raise RepositoryNotFound.new(@repo_id) unless Globals::repos.has_key?(@repo_id)
      @repo = Globals::repos[@repo_id]

      @commit_hash = params["h"] || @repo.head

      @template_params["title"] = "#{Globals::config["title"]} - #{@repo_id}"
      @template_params["commit"] = @repo.commit(@commit_hash).to_hash
      @template_params["files_list"] = @repo.list
      @template_params["repository"] = @repo.to_hash
    end

    def parse_template(name, params = @template_params)
      Liquid::Template.parse( File.open("templates/#{name}.liquid").read ).render(params)
    end

    def call(env)
      @request = Rack::Request.new(env)
      @response = Rack::Response.new

      @path = request.path_info.split(/\/+/).delete_if { |x| x.empty? }
      # Rule out the static files immediately
      static_file(".#{request.path_info}") if @path[0] == "static"
      @template_params = {
        "basepath" => request.script_name,
        "currpath" => (request.script_name + request.path_info + "/").gsub("//", "/")
      }

      @content = ""

      case path.size
      when 0 then project_list
      when 1 then project_show
      else tree_browse
      end

      @template_params["content"] = @content
      response.write parse_template("main")

      return response.finish
    rescue StaticOutput # We served a static page for whatever reason, just exit
      return response.finish
#     rescue FileNotFound => err404
#       template = Liquid::Template.parse(File.open("templates/exception.liquid").read)
#       response["status"] = CGI::HTTP_STATUS["NOT_FOUND"]
#       response.write template.render("basepath" => request.script_name,
#                                      "title" => "Not found",
#                                      "message" => err404.message,
#                                      "backtrace" => err404.backtrace)
#       return response.finish
    end

  end
end

# kate: encoding UTF-8; remove-trailing-space on; replace-trailing-space-save on; space-indent on; indent-width 3;
