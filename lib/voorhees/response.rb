module Voorhees 
  
  class Response
    
    attr_reader :klass, :json
    
    def initialize(klass, json)
      @klass = klass
      @json  = json
    end
    
    def to_objects
      @json.collect do |item|
        @klass.new_from_json(item)
      end
    end
    
  end
  
end