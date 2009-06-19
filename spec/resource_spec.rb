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
