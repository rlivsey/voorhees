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
  
  json_service  :get,  
                :path => "/users/show.json",
                :hierarchy => {
                  :status => :tweet
                }
  
  def friends
    json_request do |r|
      r.path        = "/statuses/friends.json"
      r.parameters  = {:id => self.screen_name}
      r.hierarchy   = {
        :status => :tweet
      }
    end
  end
  
end

class Tweet
  include Voorhees::Resource
  
  json_service  :public_timeline, 
                :path => "/statuses/public_timeline.json",
                :hierarchy => {
                  :user => User # can be a class
                }
                
  json_service  :users_timeline,
                :path => "/statuses/user_timeline.json",
                :hierarchy => {
                  :user => :user # or a symbol
                }
  
end

puts "> tweets = Tweet.public_timeline"
tweets = Tweet.public_timeline

puts "> tweets[0].class: #{tweets[0].class}"
puts "> tweets[0].text: #{tweets[0].text}"
puts "> tweets[0].user.name: #{tweets[0].user.name}"

puts "\n\n"
puts "> tweets = Tweet.users_timeline(:id => 'rlivsey', :page => 2)"
tweets = Tweet.users_timeline(:id => 'rlivsey', :page => 2)

puts "> tweets[0].text: #{tweets[0].text}"
puts "> tweets[0].user.name: #{tweets[0].user.name}"

puts "\n\n"

puts "> rlivsey = User.get(:id => 'rlivsey')"
rlivsey = User.get(:id => 'rlivsey')

puts "> rlivsey.name: #{rlivsey.name}"
puts "> rlivsey.location: #{rlivsey.location}"
puts "> rlivsey.status.text: #{rlivsey.status.text}"
puts "> rlivsey.status.created_at: #{rlivsey.status.created_at}"

puts "\n\n"

puts "> friends = rlivsey.friends"
friends = rlivsey.friends

puts "> friends[0].class: #{friends[0].class}"
puts "> friends[0].name: #{friends[0].name}"
puts "> friends[0].status.text: #{friends[0].status.text}"


