$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'json'            # use whatever JSON gem you want, as long as it supports JSON.parse
require 'active_support'  # used for inflector 
require 'voorhees'
require 'pp'

Voorhees::Config.setup do |c|
  c[:base_uri] = "http://twitter.com"
end

class User
  include Voorhees::Resource
end

class Tweet
  include Voorhees::Resource
  
  json_service  :public_timeline, 
                :path => "/statuses/public_timeline.json",
                :hierarchy => {
                  :user => User
                }
end

tweets = Tweet.public_timeline
puts "Found #{tweets.size} tweets, first one is:"

first = tweets[0]
puts " * Class: #{first.class}"
puts " * Contents: #{first.text}"
puts " * Name: #{first.user.name}"