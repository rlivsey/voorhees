module Voorhees 
  
  module Resource
    
    def self.included(base)
      base.extend ClassMethods    
      include InstanceMethods
    end    
    
    module ClassMethods
      
      def json_request(&block)
        block.call
      end
      
    end
    
    module InstanceMethods
      
      # simply passes it onto the class method
      def json_request(&block)
        self.class.json_request(&block)
      end
      
    end
    
  end
  
end