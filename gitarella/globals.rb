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
   class Globals
      @@cache = Hash.new
      def Globals.cache
         @@cache
      end

      def Globals.init_cache
         return unless $config["memcache-servers"] and not $config["memcache-servers"].empty?

         begin
            require "memcache"
            memcache = MemCache::new($config["memcache-servers"], :namespace => 'gitarella', :compression => 'true')
            memcache["gitarella-test"] = true
            @@cache = memcache
         rescue LoadError
            $log.error "memcache configured, but unable to load 'memcache' extension."
         rescue MemCache::MemCacheError
            $log.error "memcache configured, but no server available."
         end
      end

      @@repos = Hash.new
      def Globals.repos
         @@repos
      end

      def Globals.init_repos
         @@repos = Hash.new

         $config["repositories"].each { |repo|
            gitrepo = GITRepo.new(repo)
            @@repos[gitrepo.id] = gitrepo
         }
      end

      def Globals.init_all
         init_cache
         init_repos
      end
   end

end

# kate: encoding UTF-8; remove-trailing-space on; replace-trailing-space-save on; space-indent on; indent-width 3;