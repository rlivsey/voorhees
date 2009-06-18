require 'uri'
require 'net/http'

module Voorhees 
  
  class Request
    
    attr_accessor :timeout,   :retries,   :path, 
                  :required,  :defaults,  :parameters,
                  :base_uri
    
    def initialize(caller_class)
      @caller_class = caller_class
    end
    
    def path=(uri)
      @path = URI.parse(uri)
    end
    
    def uri
      path.relative? ? URI.parse("#{base_uri}#{path}") : path  
    end    
    
    def base_uri
      @base_uri || Voorhees::Config[:base_uri]
    end
    
    def parameters
      (@defaults || {}).merge(@parameters || {})
    end
    
    def timeout
      @timeout  || Voorhees::Config[:timeout]
    end
    
    def retries
      @retries  || Voorhees::Config[:retries]      
    end
    
    def perform
      setup_request
      parse_response(perform_actual_request)
    end
        
    private
    
      def setup_request
        @http  = Net::HTTP.new(uri.host, uri.port)
        @req   = Net::HTTP::Post.new(uri.path)
        
        @req.form_data = { Voorhees::Config[:json_parameter_name] => parameters.to_json }
        
        @http.open_timeout = timeout || Voorhees::Config[:timeout]
        @http.read_timeout = timeout || Voorhees::Config[:timeout]        
      end
    
      def perform_actual_request
        
        retries_left = retries
        
        begin        
          retries_left -= 1
          
          response = @http.start do |connection| 
            connection.request(@req) 
          end
          
        rescue Timeout::Error
          if retries_left >= 0
            Voorhees::Config.logger.debug("Retrying due to Timeout::Error (#{uri.to_s})")            
            retry
          end
          
          raise Voorhees::TimeoutError.new
          
        rescue Errno::ECONNREFUSED
          if retries_left >= 0          
            Voorhees::Config.logger.debug("Retrying due to Errno::ECONNREFUSED (#{uri.to_s})")            
            sleep(1) 
            retry
          end
          
          raise Voorhees::UnavailableError.new
          
        end

        if response.is_a?(Net::HTTPNotFound)
          Voorhees::Config.logger.error("Service Not Found (#{uri.to_s})")           
          raise Voorhees::NotFoundError.new
        end
        
        response
      end
    
      def parse_response(response)
        Voorhees::Response.new(@caller_class, JSON.parse(response.body))
        
      rescue JSON::ParserError
        raise Voorhees::ParseError
      end
    
      def validate
        raise Voorhees::ParameterMissingError if @required && !@required.all?{|x| @parameters.keys.include?(x) }
      end
    
  end
  
end