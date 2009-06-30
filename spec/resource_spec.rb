require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe User  do
  
  before :each do 
    load_json
  end
  
  describe "ClassMethods" do  
    describe "new_from_json" do
    
      it "Should create a new User" do
        User.should_receive(:new).once.and_return(mock(:user, :null_object => true))
        user_from_json
      end
    
      it "should assign the JSON to User#raw_json" do
        mock_user = mock(:user, :null_object => true)
        User.stub!(:new).and_return(mock_user)
        mock_user.should_receive(:raw_json=).with(@json)
        user_from_json
      end
    
      it "should assign the hierarchy to User#json_hierarchy" do
        mock_user = mock(:user, :null_object => true)
        User.stub!(:new).and_return(mock_user)
        mock_user.should_receive(:json_hierarchy=).with(@hierarchy)
        user_from_json
      end    
    
      it "should return the new user" do
        user_from_json.should be_an_instance_of(User)
      end  
    end
    
    describe "json_request" do
      
      before :each do 
        @json_string= "{}"
        @json_hash  = {}
        
        @request  = mock(:request,  :null_object => true)
        @response = mock(:response, :null_object => true)
        @objects  = [mock(:object)]
                
        Voorhees::Request.stub!(:new).and_return(@request)
        @request.stub!(:perform).and_return(@response)
        
        @response.stub!(:to_objects).and_return(@objects)
        @response.stub!(:json).and_return(@json_hash)        
        @response.stub!(:body).and_return(@json_string)            
      end
      
      def perform_request
        User.json_request{}
      end
      

      it "should call Request.new with the current class if no class is passed" do
        Voorhees::Request.should_receive(:new).with(User).and_return(@request)
        perform_request
      end
      
      it "should call Request.new with the specified class if a class is passed" do
        Voorhees::Request.should_receive(:new).with(Message).and_return(@request)
        User.json_request(:class => Message) do |request|
          # ...
        end
      end
      
      
      it "should yeild a request" do
        User.json_request do |r|
          r.should == @request
        end
      end
      
      it "should raise a LocalJumpError exception if a block is not given" do
        lambda{
          User.json_request
        }.should raise_error(LocalJumpError)
      end
      
      it "should implicitly call Request#perform" do
        @request.should_receive(:perform).once
        perform_request
      end
      
      it "should return the result of Response#to_objects if :returning is not set" do
        perform_request.should == @objects
      end
      
      it "should return the JSON string if :returning is set to :raw" do
        User.json_request(:returning => :raw){}.should == @json_string
      end
      
      it "should return the JSON hash if :returning is set to :json" do
        User.json_request(:returning => :json){}.should == @json_hash
      end
      
      it "should return the objects string if :returning is set to :objects" do
        User.json_request(:returning => :objects){}.should == @objects
      end
      
      it "should return the response if :returning is set to :response" do
        User.json_request(:returning => :response){}.should == @response
      end
              
    end
    
    describe "json_service" do
      
      before :each do 
        @service_name = :list
        @service_attrs = {
          :timeout  => 100,
          :required => [:monkeys]
        }
      end
      
      def define_service
        User.json_service @service_name, @service_attrs
      end
      
      it "should define a method with the same name as the service" do
        User.should_not respond_to(@service_name)
        define_service
        User.should respond_to(@service_name)        
      end       
      
      describe "calling the defined method" do
        
        before :each do
          define_service

          @request  = mock(:request,  :null_object => true)
          @response = mock(:response, :null_object => true)
          @objects  = [mock(:object)]

          Voorhees::Request.stub!(:new).and_return(@request)
          @request.stub!(:perform).and_return(@response)
        end
        
        it "should call User#json_request" do
          User.should_receive(:json_request).and_return(@response)
          User.list
        end
        
        it "should pass service attributes onto the request" do
          @service_attrs.each do |key, value|
            @request.should_receive("#{key}=").with(value)
          end
          User.list
        end
        
        it "should use any hash passed in to set the request parameters" do
          params = {:monkeys => true}
          @request.should_receive(:parameters=).with(params)
          User.list(params)
        end
        
        it "should return the result of Response#to_objects" do          
          @response.should_receive(:to_objects).and_return(@objects)          
          User.list.should == @objects
        end
      end
    end
  end

  describe "InstanceMethods" do
    
    describe "#raw_json" do
      it "should contain the raw json" do
        user_from_json.raw_json.should == @json
      end
    end
    
    describe "#json_attributes" do
      it "should contain symbols of the keys of the attributes available as underscored" do
        user_from_json.json_attributes.sort.should == [:address, :camel_case, :email, :id, :messages, :name, :pet, :username]
      end
    end
    
    describe "#json_request" do
      
      before :each do 
        @request  = mock(:request,  :null_object => true)
        @response = mock(:response, :null_object => true)
                
        Voorhees::Request.stub!(:new).and_return(@request)
        @request.stub!(:perform).and_return(@response)        
      end
      
      def perform_request
        user_from_json.json_request{}
      end      
      
      it "should pass the request to the class method" do
        User.should_receive(:json_request)
        user_from_json.json_request{}
      end
      
      it "should raise a LocalJumpError exception if a block is not given" do
        lambda{
          user_from_json.json_request
        }.should raise_error(LocalJumpError)
      end
      
      it "should implicitly call Request#perform" do
        @request.should_receive(:perform).once
        perform_request
      end
      
      it "should return the result of Request#perform" do
        perform_request.should == @response
      end
      
    end
    
    describe "calling assignment method with name of a json attribute" do

      it "should define an assignment method" do
        user = user_from_json
        
        user.should_not respond_to(:email=)
        user.email = "test"
        user.should respond_to(:email=)
      end
      
      it "should assign the value" do
        user = user_from_json
        new_email = "a_new_address@example.com"
        
        user.email = new_email
        user.email.should == new_email
      end
      
    end
    
    describe "calling method with the name of a json attribute" do
      
      it "should return the correct data from #id" do
        user = user_from_json
        user.id.should == @json["id"]
      end
      
      it "should define a method of the same name" do
        user = user_from_json
        
        user.should_not respond_to(:email)
        user.email
        user.should respond_to(:email)
      end
      
      it "should return the correct data from defined methods" do
        user = user_from_json
        
        user.email # first access, now it's defined
        user.email.should == @json["email"]
      end
      
      describe "which is a simple value" do
        it "should return the value of the attribute" do
          user_from_json.email.should == @json["email"]
        end
      end
      
      describe "which is camelCase in the JSON" do
        it "should return the value of the attribute" do
          user_from_json.camel_case.should == @json["camelCase"]
        end
      end
      
      describe "which is a collection" do
        it "should return an array" do
          user_from_json.messages.should be_an_instance_of(Array)
        end

        it "should infer the type of objects based on the collection name" do
          user_from_json.messages.each do |m|
            m.should be_an_instance_of(Message)
          end
        end        
      end
      
      describe "which is a sub-object" do
      
        it "should return as a Hash if the hierarchy is not defined" do
          @hierarchy = {
          }          
          user_from_json.pet.should be_a(Hash)
        end
        
        it "should return as the right class if the hierarchy is defined as symbol" do
          @hierarchy = {
            :address => :address
          }          
          user_from_json.address.should be_a(Address)
        end
        
        it "should return as the right class if the hierarchy is defined as Class" do
          @hierarchy = {
            :address => Address
          }
          user_from_json.address.should be_a(Address)
        end
        
        it "should return as the right class for multiple depths" do
          @hierarchy = {
            :address => [Address, {
              :coords => LatLon
            }]
          }
          user_from_json.address.coords.should be_a(LatLon)          
        end
        
      end
      
    end
    
  end
end

def load_json
  body = ''
  path = File.expand_path(File.dirname(__FILE__) + '/fixtures/user.json')
  File.open(path, 'r') do |f|
    body = f.read
  end
  @json = JSON.parse(body)
end

def user_from_json
  User.new_from_json(@json, @hierarchy)
end
