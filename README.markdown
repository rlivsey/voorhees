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
      
      json_service :list, :path => "/users/find.json"
    
      def messages
        json_request(Message) do |r|
          r.path = "/#{self.id}/messages.json"
        end
      end
    end
    
    users = User.list(:page => 2)
    
    user = users[0]
    user.json_attributes      => [:id, :login, :email]
    user.raw_json             => {:id => 1, :login => 'test', :email => 'bob@example.com'}
    user.login                => 'test'
    user.messages             => [Message, Message, Message, ...]

See [/examples/](master/examples/) directory for more.

## A bit more in-depth

### Configuration

Setup global configuration for requests with Voorhees::Config
These can all be overridden on individual requests/services

    Voorhees::Config.setup do |c|
      c[:base_uri]  = "http://api.example.com/json"
      c[:defaults]  = {:api_version => 2}
      c[:timeout]   = 10
      c[:retries]   = 3
    end

#### Global options

* logger: set a logger to use for debug messages, defaults to Logger.new(STDOUT) or RAILS_DEFAULT_LOGGER if it's defined

#### Request global options

These can be set in the global config and overridden on individual services/requests

* base_uri: Prepend all paths with this, usually the domain of the service
* defaults: A hash of default parameters
* http_method: The Net::HTTP method to use. One of Net::HTTP::Get (default), Net::HTTP::Post, Net::HTTP::Put or Net::HTTP::Delete 
* retries: Number of times to retry if it fails to load data from the service
* timeout: Number of seconds to wait for the service to send data

#### Request specific options

These cannot be globally set and can only be defined on individual services/requests

* hierarchy: Define the class hierarchy for nested data - see below for info
* parameters: Hash of data to send along with the request, overrides any defaults
* path: Path to the service. Can be relative if you have a base_uri set.
* required: Array of required parameters. Raises a Voorhees::ParameterMissingError if a required parameter is not set.

### Timeouts and Retries

As well as setting the open_timeout/read_timeout of Net::HTTP, we also wrap each request in a timeout check.

If [SystemTimer](http://ph7spot.com/articles/system_timer) is installed it will use this, otherwise it falls back on the Timeout library.

If the request fails with a Timeout::Error, or a Errno::ECONNREFUSED, we attept the request again upto the number of retries specified.

For Errno::ECONNREFUSED errors, we also sleep for 1 second to give the service a chance to wake up.

### Services and Requests

There are 3 ways to communicate with the service.

#### json_service

This sets up a class method

    class User
      include Voorhees::Resource
      json_service :list, :path => "/users.json"
    end

    User.list(:page => 3)   =>  [User, User, User, ...] 

By default it assumes you're getting items of the same class, you can override this like so:
    
    json_service :list, :path   => "/users.json",
                        :class  => OtherClass

#### json_request

This is used in instance methods:

    class User
      include Voorhees::Resource
      
      def friends
        json_request do |r|
          r.path => "/friends.json"
          r.parameters => {:user_id => self.id}
        end
      end
    end

    User.new.friends(:limit => 2)  => [User, User]

Like json_service, by default it assumes you're getting items of the same class, you can override this like so:

    def messages
      json_request(Message) do |r|
        r.path        = "/messages.json"
        r.parameters  = {:user_id => self.id}        
      end
    end

    User.new.messages  => [Message, Message, ...]

#### Voorhees::Request

Both json_service and json_request create Voorhees::Request objects to do their bidding.

If you like you can use this yourself directly.

This sets up a request identical to the json_request messages example above:

    request = Voorhees::Request.new(Message)
    request.path        = "/messages.json"
    request.parameters  = {:user_id => self.id} 
    
To perform the HTTP request  (returning a Voorhees::Response object):

    response = request.perform

You can now get at the parsed JSON, or convert them to objects:

    response.json       => [{id: 5, subject: "Test", ... }, ...]
    response.to_objects => [Message, Message, Message, ...]

### Object Hierarchies

Say you have a service which responds with a list of users in the following format:

    curl http://example.com/users.json

    [{
      "email":"bt@example.com",
      "username":"btables",
      "name":"Bobby Tables",
      "id":1,
      "address":{
        "street":"24 Monkey Close",
        "city":"Somesville",
        "country":"Somewhere",
        "coords":{
          "lat":52.9876,
          "lon":12.3456
        }
      }
    }]

You can define a service to consume this as follows:

    class User
      include Voorhees::Resource
      json_service :list, :path => "http://example.com/users.json"
    end

Calling User.list will return a list of User instances.

    users = User.list
    users[0].name => "bt@example.com"

However, what about the address? It just returns as a Hash of parsed JSON:

    users[0].address => {"street":"24 Monkey Close", "city":... }
    
If you have an Address class you'd like to use, you can tell it like so:

    json_service :list, :path      => "http://example.com/users.json",
                        :hierarchy => {:address => Address}

You can nest hierarchies to an infinite depth like so:

    json_service :list, :path      => "http://example.com/users.json",
                        :hierarchy => {:address => [Address, {:coords => LatLon}]}

Instead of the class name, you can also just use a symbol:

    json_service :list, :path      => "http://example.com/users.json",
                        :hierarchy => {:address => [:address, {:coords => :lat_lon}]}

With that we can now do:

    users = User.list
    users[0].name               => "Bobby Tables"
    users[0].address.country    => "Somewhere"
    users[0].address.coords.lat => 52.9876
    
## Thanks

The ideas and design came from discussions when refactoring [LVS::JSONService](http://github.com/LVS/JSONService) the original of which was 
developed by [Andy Jeffries](http://github.com/andyjeffries/) for use at LVS

Much discussion with [John Cinnamond](http://github.com/jcinnamond) 
and [Jason Lee](http://github.com/jlsync)

## Copyright

Copyright (c) 2009 Richard Livsey. See LICENSE for details.
