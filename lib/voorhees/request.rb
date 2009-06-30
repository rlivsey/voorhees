require 'uri'
require 'net/http'

begin
  require 'system_timer'
  VoorheesTimer = SystemTimer
rescue LoadError
  require 'timeout'
  VoorheesTimer = Timeout
end

module Voorhees 
  
  class Request
    
    attr_accessor :timeout,   :retries,     :path, 
                  :required,  :defaults,    :parameters,
                  :base_uri,  :http_method, :hierarchy
    
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
    
    def defaults
      @defaults || Voorhees::Config[:defaults]
    end
    
    def parameters
      (defaults || {}).merge(@parameters || {})
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
      build_response(perform_actual_request)
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
        
        @http.open_timeout = timeout
        @http.read_timeout = timeout
      end
    
      def perform_actual_request
        retries_left = retries
        
        Voorhees.debug("Performing #{http_method} request for #{uri.to_s}")
        
        begin        
          retries_left -= 1
          
          response = VoorheesTimer.timeout(timeout) do
                       @http.start do |connection| 
                         connection.request(@req) 
                       end
                     end
          
        rescue Timeout::Error
          if retries_left >= 0
            Voorhees.debug("Retrying due to Timeout::Error (#{uri.to_s})")            
            retry
          end
          
          Voorhees.debug("Request failed due to Timeout::Error (#{uri.to_s})")
          raise Voorhees::TimeoutError.new
          
        rescue Errno::ECONNREFUSED
          if retries_left >= 0          
            Voorhees.debug("Retrying due to Errno::ECONNREFUSED (#{uri.to_s})")            
            sleep(1) 
            retry
          end
          
          Voorhees.debug("Request failed due to Errno::ECONREFUSED (#{uri.to_s})")
          raise Voorhees::UnavailableError.new
          
        end

        if response.is_a?(Net::HTTPNotFound)
          Voorhees.debug("Request failed due to Net::HTTPNotFound (#{uri.to_s})")           
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
    
      def build_response(response)
        Voorhees::Config[:response_class].new(response.body, @caller_class, @hierarchy)
      end
    
      def validate
        raise Voorhees::ParameterMissingError if @required && !@required.all?{|x| @parameters.keys.include?(x) }
      end
    
      def post?
        http_method == Net::HTTP::Post
      end
    
  end
  
end