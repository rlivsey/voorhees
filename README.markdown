# Voorhees

## Design goals

* Be as fast as possible
* Be simple, yet configurable
* Include just what you need
* Don't stomp on object hierarcy (it's a mixin)
* Lazy load only the objects you need, when you need them

## Example usage

    class User
    
      include Voorhees::Resource
      
      json_service :list, :path     => "/users/find.json",
                          :defaults => {:all => true}, 
                          :required => [:filter],
                          :timeout  => 10.seconds
            
      def self.get(id)
        json_request do |r|
          r.path        = "/users/get.json"
          r.parameters  = {:id => id}
          r.timeout     = 10
          r.retries     = 5
        end
      end
    
      def messages
        json_request(Message) do |r|
          r.path = "/#{self.id}/messages.json"
        end
      end
    
    end
    
    user = User.get(1)
    user.json_attributes      => [:id, :login, :email]
    user.raw_json             => {:id => 1, :login => 'test', :email => 'bob@example.com'}
    user.login                => 'test'
    user.login = 'new login'
    user.login                => 'new login'
    
    user.messages             => [Message, Message, Message, ...]
    
    User.list(:filter => 'xxx') => [User, User, User, ...]
    User.list(:blah => false)   => raises ParameterRequiredException
    etc...

## Configuration

Setup global configuration for requests with Voorhees::Config
These can all be overridden on individual requests/services

    Voorhees::Config.setup do |c|
      c[:logger]    = RAILS_DEFAULT_LOGGER
      c[:base_uri]  = "http://api.example.com/json"
      c[:required]  = [:something]
      c[:defaults]  = {:api_version => 2}
      c[:timeout]   = 10
      c[:retries]   = 3
    end

## Thanks

The ideas and design came from discussions when refactoring [LVS::JSONService](http://github.com/LVS/JSONService) the original of which was 
developed by [Andy Jeffries](http://github.com/andyjeffries/) for use at LVS

Much discussion with [John Cinnamond](http://github.com/jcinnamond) 
and [Jason Lee](http://github.com/jlsync)

## Copyright

Copyright (c) 2009 Richard Livsey. See LICENSE for details.
