module Voorhees 
  
  class Response
    
    attr_reader :body, :klass
    
    def initialize(body, klass=nil, hierarchy=nil)
      @body       = body
      @hierarchy  = hierarchy
      @klass      = klass      
    end
    
    def json
      @json ||= JSON.parse(@body)
    rescue JSON::ParserError
      Voorhees.debug("Parsing JSON failed.\nFirst 500 chars of body:\n#{response.body[0...500]}")
      raise Voorhees::ParseError
    end
    
    def to_objects
      return unless @klass
      
      raise Voorhees::NotResourceError.new unless @klass.respond_to?(:new_from_json)
      
      if json.is_a?(Array)
        json.collect do |item|
          @klass.new_from_json(item, @hierarchy)
        end
      else
        @klass.new_from_json(json, @hierarchy)
      end
    end
    
  end
  
end