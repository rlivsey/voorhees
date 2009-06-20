require 'spec'
require 'rubygems'
require 'json'
require 'active_support'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'voorhees'

require File.expand_path(File.dirname(__FILE__) + '/fixtures/resources')

Spec::Runner.configure do |config|
  
end

# allow sorting by symbol
class Symbol
  def <=>(a)
    self.to_s <=> a.to_s
  end
end

