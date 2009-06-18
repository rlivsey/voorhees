require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Voorhees::Config do

  before :each do 
    
    Voorhees::Config.clear
    Voorhees::Config.setup do |c|
      c[:one] = 1
      c[:two] = 2
    end
    
  end

  describe "configuration" do
    
    it "should return the configuration hash" do
      Voorhees::Config.configuration.should == {:one => 1, :two => 2}
    end
    
  end
  
  describe "[]" do
    
    it "should return the config option matching the key" do
      Voorhees::Config[:one].should == 1
    end
    
    it "should return nil if the key doesn't exist" do
      Voorhees::Config[:monkey].should be_nil
    end
    
  end
  
  describe "[]=" do
    
    it "should set the config option for the key" do
      lambda{
        Voorhees::Config[:banana] = :yellow        
      }.should change(Voorhees::Config, :banana).from(nil).to(:yellow)      
    end
    
  end
  
  describe "delete" do
    
    it "should delete the config option for the key" do
      lambda{
        Voorhees::Config.delete(:one)
      }.should change(Voorhees::Config, :one).from(1).to(nil)      
    end
    
    it "should leave the config the same if the key doesn't exist" do
      lambda{
        Voorhees::Config.delete(:test)        
      }.should_not change(Voorhees::Config, :configuration)
    end
    
  end
  
  describe "fetch" do
    
    it "should return the config option matching the key if it exists" do
      Voorhees::Config.fetch(:one, 100).should == 1
    end
    
    it "should return the config default if the key doesn't exist" do
      Voorhees::Config.fetch(:other, 100).should == 100      
    end
    
  end
  
  describe "to_hash" do
    
    it "should return a hash of the configuration" do
      Voorhees::Config.to_hash.should == {:one => 1, :two => 2}      
    end
    
  end
  
  describe "setup" do
    
    it "should yield the configuration object" do
      Voorhees::Config.setup do |c|
        c.should == Voorhees::Config.configuration
      end
    end
    
    it "should let you set items on the configuration object" do
      lambda{
        Voorhees::Config.setup do |c|
          c[:bananas] = 100
        end
      }.should change(Voorhees::Config, :bananas).from(nil).to(100)      
    end
    
  end
  
  describe "calling a missing method" do
    
    it "should retreive the config if the method matches a key" do
      Voorhees::Config.one.should == 1
    end
    
    it "should retreive nil if the method doesn't match a key" do
      Voorhees::Config.moo.should be_nil
    end
    
    it "should set the value of the config item matching the method name if it's an assignment" do
      lambda{
        Voorhees::Config.trees = 3
      }.should change(Voorhees::Config, :trees).from(nil).to(3)            
    end        
    
  end

end
