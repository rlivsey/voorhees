require 'uri'
require 'net/http'

module Voorhees 
  
  class Request
    
    attr_accessor :timeout,   :retries,   :path, 
                  :required,  :defaults,  :parameters,
                  :base_uri,  :http_method
    
    def initialize(caller_class=nil)
      @caller_class = caller_class
    end
    
    def path=(uri)
      @path = URI.parse(uri)
    end
    
    def uri
      u = path.relative? ? URI.parse("#{base_uri}#{path}") : path  
      if query = query_string(u)
        u.query = query
      end
      u
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
    
    def http_method
      @http_method  || Voorhees::Config[:http_method]      
    end
    
    def perform
      setup_request
      parse_response(perform_actual_request)
    end
        
    private
    
      def setup_request
        @http  = Net::HTTP.new(uri.host, uri.port)
        @req   = http_method.new(uri.path)
        
        @req.form_data =  if Voorhees::Config[:post_json] 
                            { Voorhees::Config[:post_json_parameter] => parameters.to_json }
                          else
                            parameters
                          end
        
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
    
      def query_string(uri)
        return if post?
        query_string_parts = []
        query_string_parts << uri.query unless uri.query.blank?
        query_string_parts += parameters.collect{|k,v| "#{k}=#{v}" } unless parameters.empty?
        query_string_parts.size > 0 ? query_string_parts.join('&') : nil
      end
    
      def parse_response(response)
        Voorhees::Response.new(JSON.parse(response.body), @caller_class)
        
      rescue JSON::ParserError
        raise Voorhees::ParseError
      end
    
      def validate
        raise Voorhees::ParameterMissingError if @required && !@required.all?{|x| @parameters.keys.include?(x) }
      end
    
      def post?
        http_method == Net::HTTP::Post
      end
    
  end
  
end