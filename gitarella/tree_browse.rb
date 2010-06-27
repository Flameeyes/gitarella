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
class LCSDiff
   attr_reader :difflines

   def initialize()
      @difflines = Array.new
   end

   def match(event)
      @difflines << { "status" => "match", "line" => event.old_element }
   end

   def discard_b(event)
      @difflines << { "status" => "added", "line" => event.new_element }
   end

   def discard_a(event)
      @difflines << { "status" => "removed", "line" => event.old_element }
   end
end

class GitarellaCGI
   def tree_browse
      get_repo_id

      @filepath = @path.join('/')
      raise RepoFileNotFound.new(@repo_id, @filepath) if @repo.list(@filepath).empty?

      @template_params["path"] = Array.new
      prev_element = ""
      @path.each { |element|
         @template_params["path"] << { "path" => prev_element + "/" + element, "name" => element }
         prev_element = element
      }

      if @repo.list(@filepath)[0]["type"] == "tree"
         @template_params["repopath"] = "/" + @filepath
         @template_params["files_list"] = @repo.list(@filepath + "/")
         @content = parse_template("tree")
      else
         @template_params["file"] = @repo.list(@filepath)[0]
         @template_params["file"]["data"] = @repo.file(@filepath, @cgi["blobh"])
         binary = @template_params["file"]["data"] =~ /[^\x20-\x7e\s]{4,5}/

         case @cgi["mode"]
            when "blobdiff" then
               raise BinaryOperationInvalid if binary
               blob_diff
            when "checkout" then static_data(@template_params["file"]["data"])
            else
               static_data(@template_params["file"]["data"]) if binary
               @template_params["file"]["lines"] = @template_params["file"]["data"].encode_entities.split("\n")
               @content = parse_template("blob")
         end
      end
   end

   def blob_diff
      begin
         require 'rubygems'
         gem 'diff-lcs', "1.1.2"
      rescue LoadError
         require 'diff/lcs'
      end

      require 'diff/lcs/string'
      require 'text/format'

      tf = Text::Format.new
      tf.tabstop = 4
      preprocess = lambda { |line| tf.expand(line.chomp) }

      @template_params["commit"] = @repo.commit(@commit_hash).to_hash
      @template_params["old"] = Hash.new
      @template_params["old"]["sha1"] = @cgi["hp"]
      @template_params["old"]["data"] = @repo.file(@filepath, @cgi["hp"]).encode_entities.split("\n").map(&preprocess)
      @template_params["new"] = Hash.new
      @template_params["new"]["sha1"] = @cgi["hn"]
      @template_params["new"]["data"] = @repo.file(@filepath, @cgi["hn"]).encode_entities.split("\n").map(&preprocess)

      diff = LCSDiff.new
      Diff::LCS.traverse_sequences(@template_params["old"]["data"], @template_params["new"]["data"], diff)
      @template_params["difflines"] = diff.difflines

      @content = parse_template("blobdiff")
   end

   def static_data(data)
      begin
         require "filemagic"
         contentmime = FileMagic.new(FileMagic::MAGIC_MIME).buffer(data)
      rescue LoadError
         Globals::log.error "unable to load 'filemagic' extension, mime support will be disabled."
         contentmime = "application/octet-stream"
      end
      @cgi.out({ "content-type" => contentmime}) { data }
      raise StaticOutput
   end
end
end

# kate: encoding UTF-8; remove-trailing-space on; replace-trailing-space-save on; space-indent on; indent-width 3;
