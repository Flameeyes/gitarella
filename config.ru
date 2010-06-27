require 'gitarella/gitarella'

gem 'ruby-debug'
require 'ruby-debug'
::Debugger.start
puts "=> Debugger enabled"

use Rack::ShowExceptions
use Rack::Reloader
run Gitarella::GitarellaCGI.new
