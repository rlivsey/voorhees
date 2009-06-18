= Voorhees

== Design goals

* Be as fast as possible
* Be simple, yet configurable
* Include just what you need
* Don't stomp on object hierarcy (it's a mixin)
* Lazy load only the objects you need, when you need them

== Example usage

    class User
    
      include Voorhees::Service
      include Voorhees::Cachable
      include Voorhees::Encrypted
      
      json_service :list, :defaults => {:all => true}, 
                          :required => [:filter],
                          :timeout  => 10.seconds,
                          :cache    => 10.minutes,
                          :encrypted=> true
      
      def self.get(id)
        json_request do |request|
          request.url         = "http://example.com/users/get"
          request.parameters  = {:id => id}
          request.timeout     = 10
          request.retries     = 5
        end
      end
    
      def messages
        json_request do |request|
          request.url         = "http://example.com/users/#{self.id}/messages"
          request.item_klass  = Message
        end
      end
    
    end
    
    user = User.get(1)
    user.json_attributes      => [:id, :login, :email]
    user.json_data            => {:id => 1, :login => 'test', :email => 'bob@example.com'}
    user.login                => 'test'
    user.login = 'new login'
    user.login                => 'new login'
    
    User.list(:filter => 'xxx') => [User, User, User, ...]
    User.list(:blah => false)   => raises ParameterRequiredException
    etc...

== Configuration

Setup global configuration useing Voorhees::Config
These can all be overridden on individual requests/services

    Voorhees::Config.setup do |c|
      c[:logger]    = RAILS_DEFAULT_LOGGER
      c[:timeout]   = 10
      c[:retries]   = 3
      c[:encrypted] = true
    end

== Thanks

The ideas and design came from discussions when refactoring LVS::JSONService the original of which was 
developed by Andy Jeffries (http://github.com/andyjeffries/) for use at LVS

Much discussion with John Cinnamond (http://github.com/jcinnamond) 
and Jason Lee (http://github.com/jlsync)

== Copyright

Copyright (c) 2009 Richard Livsey. See LICENSE for details.
