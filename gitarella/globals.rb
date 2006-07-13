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
         Globals::log.error "memcache configured, but unable to load 'memcache' extension."
      rescue MemCache::MemCacheError
         Globals::log.error "memcache configured, but no server available."
      end
   end

   @@repos = nil
   def Globals.repos
      init_repos unless @@repos
      @@repos
   end

   def Globals.init_repos
      @@repos = Hash.new

      $config["repositories"].each { |repo|
         gitrepo = GITRepo.new(repo)
         @@repos[gitrepo.id] = gitrepo
      }
   end

   def Globals.log
      @@log
   end

   def Globals.init_log
      case $config["logging"]["enabled"].to_s.downcase
         when "false", "no", "0"
            throw NotImplemented_TODO.new
      end

      begin
         require 'rubygems'
         require_gem 'log4r'
      rescue LoadError
         require 'log4r'
      end
      @@log = Log4r::Logger.new('gitarella')

      case $config["logging"]["output"].to_s.downcase
         when "syslog"
            @@log.outputters = Log4r::SyslogOutputter.new("gitarella")
         else
            @@log.outputters = Log4r::Outputter.stderr
      end
   end

   def Globals.init_all
      init_log
      init_cache
   end
end
end

# kate: encoding UTF-8; remove-trailing-space on; replace-trailing-space-save on; space-indent on; indent-width 3;
