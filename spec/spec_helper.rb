require 'spec'
require 'rubygems'
require 'json'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'voorhees'

require File.expand_path(File.dirname(__FILE__) + '/fixtures/user')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/message')

Spec::Runner.configure do |config|
  
end
