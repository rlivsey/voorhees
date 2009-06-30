module Voorhees 
  
  module Resource
    
    def self.included(base)
      base.extend ClassMethods    
      base.send :include, InstanceMethods
      
      base.instance_eval do
        attr_accessor :raw_json, :json_hierarchy
        undef_method :id        
      end
    end    
    
    module ClassMethods
      def new_from_json(json, hierarchy=nil)
        obj = self.new
        obj.raw_json       = json
        obj.json_hierarchy = hierarchy
        obj
      end
      
      def json_service(name, request_options={})
        klass = request_options.delete(:class) || self
        (class << self; self; end).instance_eval do
          define_method name do |*args|
            params = args[0]
            json_request(:class => klass) do |r|
              r.parameters = params if params.is_a?(Hash)
              request_options.each do |option, value|
                r.send("#{option}=", value)
              end
            end
          end
        end
      end
      
      def json_request(options={})
        request = Voorhees::Request.new(options[:class] || self)
        yield request
        response = request.perform
        
        case options[:returning]
        when :raw
          response.body
        when :json
          response.json
        when :response
          response
        else
          response.to_objects
        end
      end
    end
    
    module InstanceMethods
      
      def json_attributes
        @json_attributes ||= @raw_json.keys.collect{|x| x.underscore.to_sym}
      end
      
      def json_request(options={})
        self.class.json_request(options) do |r|
          yield r
        end
      end
      
      def method_missing(*args)
        method_name = args[0]
        if json_attributes.include?(method_name)
          value = value_from_json(method_name)
          build_methods(method_name, value)
          value
        elsif method_name.to_s =~ /(.+)=$/ && json_attributes.include?($1.to_sym)
          build_methods($1, args[1])
        else        
          super
        end
      end
      
      private
        
        def value_from_json(method_name)
          item = raw_json[method_name.to_s] || raw_json[method_name.to_s.camelize(:lower)]
          
          sub_hierarchy = nil
          if json_hierarchy && hierarchy = json_hierarchy[method_name] 
            if hierarchy.is_a?(Array)
              klass         = hierarchy[0]
              sub_hierarchy = hierarchy[1]
            else
              klass = hierarchy
            end
            
            klass = Object.const_get(klass.to_s.pluralize.classify) if klass.is_a?(Symbol)
          end
          
          if item.is_a?(Array)
            build_collection_from_json(method_name, item, klass, sub_hierarchy)
          else
            build_item(item, klass, sub_hierarchy)
          end
        end
        
        def build_methods(name, value)
          self.instance_variable_set("@#{name}".to_sym, value)
          
          instance_eval "          
            def #{name}
              @#{name} ||= value_from_json(:#{name})
            end
          
            def #{name}=(val)
              @#{name} = val
            end
          "
        end
        
        def build_item(json, klass, hierarchy)
          if klass
            raise Voorhees::NotResourceError.new unless klass.respond_to?(:new_from_json)
            klass.new_from_json(json, hierarchy)
          else
            json
          end
        end
        
        def build_collection_from_json(name, json, klass, hierarchy)
          klass ||= Object.const_get(name.to_s.classify)
          json.collect do |item|
            klass.new_from_json(json, hierarchy)
          end
        rescue NameError
          json
        end
      
    end
    
  end
  
end