require 'gitarella/gitarella'

require 'ruby-debug'
::Debugger.start

use Rack::ShowExceptions
use Rack::Reloader
run Gitarella::GitarellaCGI.new
