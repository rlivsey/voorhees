require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Voorhees::Response do

  before :each do 
    User.stub!(:new_from_json).and_return(User.new)
  end

  describe "to_objects" do

    describe "with no class set" do
      
      before :each do
        @klass = nil
        build_response(:users)
      end
      
      it "should return nil" do
        @response.to_objects.should be_nil
      end
      
    end

    describe "with a class which does not have Voorhees::Resource mixed in" do
      
      before :each do 
        @klass = NotResource
        build_response(:users)
      end
      
      it "should raise a Voorhees::NotResourceError exception" do
        lambda{
          @response.to_objects
        }.should raise_error(Voorhees::NotResourceError)
      end
      
    end

    describe "with a class of User" do

      before :each do 
        @klass = User        
      end

      describe "with JSON containing an array of 2 users" do

        before :each do
          build_response(:users)
        end

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

      describe "with JSON containing one user" do

        before :each do
          build_response(:user)
        end

        it "should return one user object" do
          user = @response.to_objects
          user.should be_an_instance_of(User)
        end

      end
    end
  end
end

def build_response(fixture)
  body = ''
  path = File.expand_path(File.dirname(__FILE__) + "/fixtures/#{fixture}.json")
  File.open(path, 'r') do |f|
    body = f.read
  end

  @response = Voorhees::Response.new(JSON.parse(body), @klass)
end
