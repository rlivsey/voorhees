module Voorhees 
  
  module Resource
    
    def self.included(base)
      base.extend ClassMethods    
      base.send :include, InstanceMethods
      
      base.instance_eval do
        attr_accessor :raw_json
      end
    end    
    
    module ClassMethods
      def new_from_json(json)
        obj = self.new
        obj.raw_json = json
        obj
      end
    end
    
    module InstanceMethods
      
      def json_attributes
        @json_attributes ||= @raw_json.keys.collect{|x| x.to_sym}
      end
      
      def method_missing(*args)
        if json_attributes.include? args[0]
          return raw_json[args[0].to_s]
        end
        super
      end
      
    end
    
  end
  
end