require 'rubygems'

gem 'htmlentities', "~> 4.2"
require 'htmlentities'

class String
  def encode_entities
    @@html_coder ||= HTMLEntities.new('xhtml1')
    @@html_coder.encode(self)
  end
end
