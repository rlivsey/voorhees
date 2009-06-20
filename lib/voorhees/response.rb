module Voorhees 
  
  class Response
    
    attr_reader :klass, :json
    
    def initialize(klass, json)
      @klass = klass
      @json  = json
    end
    
    def to_objects
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