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
        mock_user = mock(:user)
        User.stub!(:new).and_return(mock_user)
        mock_user.should_receive(:raw_json=).with(@json)
        user_from_json
      end
    
      it "should return the new user" do
        user_from_json.should be_an_instance_of(User)
      end  
    end
    
    describe "json_request" do
      
      before :each do 
        @request  = mock(:request,  :null_object => true)
        @response = mock(:response, :null_object => true)
        @objects  = [mock(:object)]
                
        Voorhees::Request.stub!(:new).and_return(@request)
        @request.stub!(:perform).and_return(@response)
        @response.stub!(:to_objects).and_return(@objects)
      end
      
      def perform_request
        User.json_request{}
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
      
      it "should return the result of Response#to_objects" do
        perform_request.should == @objects
      end
    end
    
    describe "json_service" do
      
      before :each do 
        @service_name = :list
        @service_attrs = {
          :timeout  => 100,
          :required => [:monkeys]
        }
        @user = User.new
      end
      
      def define_service
        User.json_service @service_name, @service_attrs
      end
      
      it "should define a method with the same name as the service" do
        @user.should_not respond_to(@service_name)
        define_service
        @user.should respond_to(@service_name)        
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
          @user.should_receive(:json_request).and_return(@response)
          @user.list
        end
        
        it "should pass service attributes onto the request" do
          @service_attrs.each do |key, value|
            @request.should_receive("#{key}=").with(value)
          end
          @user.list
        end
        
        it "should use any hash passed in to set the request parameters" do
          params = {:monkeys => true}
          @request.should_receive(:parameters=).with(params)
          @user.list(params)
        end
        
        it "should return the result of Response#to_objects" do          
          @response.should_receive(:to_objects).and_return(@objects)          
          @user.list.should == @objects
        end
      end
    end
  end

  describe "InstanceMethods" do
    
    before :each do 
      user_from_json
    end
    
    describe "#raw_json" do
      it "should contain the raw json" do
        @user.raw_json.should == @json
      end
    end
    
    describe "#json_attributes" do
      it "should contain symbols of the keys of the attributes available" do
        @user.json_attributes.sort.should == [:email, :id, :messages, :name, :username]
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
        @user.json_request{}
      end      
      
      it "should pass the request to the class method" do
        User.should_receive(:json_request)
        @user.json_request{}
      end
      
      it "should raise a LocalJumpError exception if a block is not given" do
        lambda{
          @user.json_request
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
    
    describe "calling method with the name of a json attribute" do
      
      it "should return the value of the attribute" do
        @user.email.should == @json["email"]
      end
      
    end
    
    describe "calling a method with the name of a json collection" do

      it "should return an array" do
        @user.messages.should be_an_instance_of(Array)
      end
      
      it "should infer the type of objects based on the collection name" do
        @user.messages.each do |m|
          m.should be_an_instance_of(Message)
        end
      end
    end
  end
end

def load_json
  body = ''
  path = File.expand_path(File.dirname(__FILE__) + '/fixtures/users.json')
  File.open(path, 'r') do |f|
    body = f.read
  end
  @json = JSON.parse(body)[0]
end

def user_from_json
  @user = User.new_from_json(@json)
end
