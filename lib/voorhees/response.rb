module Voorhees 
  
  class Response
    
    attr_reader :json, :klass
    
    def initialize(json, klass=nil)
      @json  = json
      @klass = klass      
    end
    
    def to_objects
      return unless @klass
      
      raise Voorhees::NotResourceError.new unless @klass.respond_to?(:new_from_json)
      
      if @json.is_a?(Array)
        @json.collect do |item|
          @klass.new_from_json(item)
        end
      else
        @klass.new_from_json(@json)
      end
    end
    
  end
  
end