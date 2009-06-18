require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Voorhees::Response do
  
  before :each do 
    build_response    
    User.stub!(:new_from_json).and_return(User.new)
  end
  
  describe "to_objects" do
    
    it "should return an array of 2 user objects" do
      users = @response.to_objects
      users.length.should == 2
      users.each do |u|
        u.should be_an_instance_of(User)
      end
    end
    
    it "should create users by sending the JSON to User.new_from_json" do
      User.should_receive(:new_from_json).with(@response.json[0]).ordered
      User.should_receive(:new_from_json).with(@response.json[1]).ordered      
      @response.to_objects
    end
    
  end
  
end

def build_response
  body = ''
  path = File.expand_path(File.dirname(__FILE__) + '/fixtures/users.json')
  File.open(path, 'r') do |f|
    body = f.read
  end

  @response = Voorhees::Response.new(User, JSON.parse(body))
end
