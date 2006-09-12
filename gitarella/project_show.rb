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
class GitarellaCGI
   def project_show
      get_repo_id

      mode = @cgi.has_key?("mode") ? @cgi["mode"] : "tree"
      case mode
         when "summary"
            @template_params["commits"] = Globals::repos[@repo_id].commits(15, 0, @commit_hash).collect { |c| c.to_hash }
            @content = parse_template("project-summary")

         when "shortlog", "log"
            start = @cgi.has_key?("start") ? @cgi["start"].to_i : 0
            @template_params["commits"] = Globals::repos[@repo_id].commits(30, start, @commit_hash).collect { |c| c.to_hash }

            @template_params["prev_commits"] =
               if start == 0 then false
               elsif (start-30) < 0 then 0
               else start-30
               end
            @template_params["more_commits"] = start + 30

            @content = parse_template("project-" + mode)

         when "commit"
            @template_params["commit"] = @repo.commit(@commit_hash).to_hash
            @template_params["commit"]["changes"] = @repo.commit(@commit_hash).changes
            @content = parse_template("project-commit")

         when "tag"
            @template_params["tag"] = GITTag.get(@repo, @cgi["htag"]).to_hash
            @content = parse_template("project-tag")

         when "commitdiff"
            throw NotImplemented_TODO.new

         # Should this be really a fallback, or would be an exception handling
         # a bit better?
         else # fallback
            @content = parse_template("tree")
      end
   end
end
end

# kate: encoding UTF-8; remove-trailing-space on; replace-trailing-space-save on; space-indent on; indent-width 3;
