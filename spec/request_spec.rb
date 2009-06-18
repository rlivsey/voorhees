require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Voorhees::Request do
  
  before :each do 
    @request = Voorhees::Request.new
    
    # disable the logger
    Voorhees::Config.logger = mock(:logger, :null_object => true)
  end
  
  describe "global defaults" do
    
    before :each do
      Voorhees::Config.setup do |c|
        c.timeout = 1
        c.retries = 50
      end
    end
    
    it "should override the global defaults if overridden" do
      @request.timeout = 100
      @request.timeout.should == 100
    end
    
    it "should default to the global defaults if not overridden" do
      @request.retries.should == 50
    end
    
  end
  
  describe "defaults" do
    
    it "should be included in the parameters" do
      @request.defaults   = {:all => true}
      @request.parameters = {:order => 'surname'}
      @request.parameters.should == {:all => true, :order => 'surname'}      
    end
    
    it "should be overridden by matching parameters" do
      @request.defaults   = {:all => true, :order => 'surname'}
      @request.parameters = {:all => false}
      @request.parameters.should == {:all => false, :order => 'surname'}
    end    
  
  end
  
  
  describe "uri" do
    
    before :each do
      @base = "http://example.com"
      @path = "/some/path"
      Voorhees::Config.base_uri = @base
    end
    
    it "should prepend the base_uri if it's given relative path" do
      @request.path = @path
      @request.uri.to_s.should == "#{@base}#{@path}"
    end
    
    it "should not prepend the base_uri if it's given a full URI" do
      uri = "http://google.com/somewhere/"
      @request.path = uri
      @request.uri.to_s.should == uri
    end
    
  end  
  
  describe "validation" do
    
    before :each do 
      @request.required = [:id, :login]
    end
    
    it "should raise Voorhees::ParameterMissingError if the params do not contain a required item" do
      @request.parameters = {:id => 1}
      
      lambda{
        @request.send(:validate)
      }.should raise_error(Voorhees::ParameterMissingError)
    end
    
    it "should not raise Voorhees::ParameterMissingError if the params contain all required items" do
      @request.parameters = {:id => 1, :login => 'test'}      
      
      lambda{
        @request.send(:validate)
      }.should_not raise_error(Voorhees::ParameterMissingError)
    end
    
  end
    
  describe "perform" do
    
    before :each do
      @host   = "example.com"
      @port   = 8080
      @path   = "/endpoint"
      @params = {:bananas => 5}
      
      @request.path       = "http://#{@host}:#{@port}#{@path}"
      @request.timeout    = 10
      @request.retries    = 0
      @request.parameters = @params
      
      @mock_post = mock(:post, :null_object => true)
      Net::HTTP::Post.stub!(:new).and_return(@mock_post)

      body = '{"something":"result"}'
      @json_response = Net::HTTPResponse::CODE_TO_OBJ["200"].new("1.1", 200, body)
      @json_response.stub!(:body).and_return(body)
      
      @mock_http  = MockNetHttp.new
      @connection = @mock_http.connection
      @connection.stub!(:request).and_return(@json_response)      
      Net::HTTP.stub!(:new).and_return(@mock_http)
    end    
    
    
    def perform_catching_errors
      @request.perform
    rescue
    end
    
    it "should create a Net::HTTP object with the correct host and port" do
      Net::HTTP.should_receive(:new).with(@host, @port).and_return(@mock_http)
      @request.perform
    end
    
    it "should perform a HTTP request to the correct path" do
      Net::HTTP::Post.should_receive(:new).with(@path).and_return(@mock_post)
      @request.perform
    end
    
    it "should set Net::HTTP#open_timeout" do
      @mock_http.should_receive(:open_timeout=).with(@request.timeout)
      @request.perform   
    end

    it "should set Net::HTTP#read_timeout" do
      @mock_http.should_receive(:read_timeout=).with(@request.timeout)      
      @request.perform     
    end    

    it "should assign the JSON parameters to a Net::HTTP::Post object" do
      @mock_post.should_receive(:form_data=).with({ Voorhees::Config[:json_parameter_name] => @params.to_json })
      @request.perform
    end

    it "should send one request to Net::HTTP#start" do
      @connection.should_receive(:request).once.with(@mock_post)
      @request.perform
    end

    it "should return the response from the service" do
      @connection.should_receive(:request).and_return(@json_response)
      @request.perform.body.should == @json_response.body
    end    

    
    describe "with TimeoutError" do
      
      it "should raise a Voorhees::TimeoutError" do
        @connection.stub!(:request).and_raise(Timeout::Error.new(nil))
        
        lambda{
          @request.perform
        }.should raise_error(Voorhees::TimeoutError)
      end
      
      describe "with retries" do

        before :each do
          @request.retries = 2          
        end

        describe "with subsequent success" do

          it "should post the request 2 times" do
            @connection.should_receive(:request).with(@mock_post).exactly(1).times.ordered.and_raise(Timeout::Error.new(nil))                
            @connection.should_receive(:request).with(@mock_post).exactly(1).times.ordered
            @request.perform                
          end   

          it "should return the response from the service" do
            @connection.should_receive(:request).with(@mock_post).exactly(1).times.ordered.and_raise(Timeout::Error.new(nil))                
            @connection.should_receive(:request).with(@mock_post).exactly(1).times.ordered.and_return(@json_response)
            @request.perform.body.should == @json_response.body
          end

        end

        describe "with subseqent failure" do

          before :each do
            @connection.stub!(:request).and_raise(Timeout::Error.new(nil))
          end

          it "should post the request 3 times (original + 2 retries)" do
            @connection.should_receive(:request).with(@mock_post).exactly(3).times.and_raise(Timeout::Error.new(nil))        
            perform_catching_errors
          end

          it "should raise an Voorhees::TimeoutError exception" do
            lambda {
              @request.perform
            }.should raise_error(Voorhees::TimeoutError)
          end
        end
      end
    end
    
    
    describe "with Net::HTTPNotFound" do
      
      it "should raise a Voorhees::NotFoundError" do
        @connection.stub!(:request).and_return(Net::HTTPNotFound.new(404, 1.1, "Not Found"))
        
        lambda{
          @request.perform
        }.should raise_error(Voorhees::NotFoundError)
      end      
      
      describe "with retries" do
        
        before :each do
          @request.retries  = 2          
        end        
        
        it "should not retry" do
          @connection.should_receive(:request).with(@mock_post).exactly(1).times.and_return(Net::HTTPNotFound.new(404, 1.1, "Not Found"))             
          perform_catching_errors
        end
      end
    end
    
    
    describe "with Errno::ECONNREFUSED" do
      
      it "should raise a Voorhees::UnavailableError" do
        @connection.stub!(:request).and_raise(Errno::ECONNREFUSED)
        
        lambda{
          @request.perform
        }.should raise_error(Voorhees::UnavailableError)
      end      
      
      it "should not sleep" do
        @connection.stub!(:request).and_raise(Errno::ECONNREFUSED)        
        @request.should_not_receive(:sleep)
        perform_catching_errors
      end      
      
      describe "with retries" do

        before :each do
          @request.retries  = 2          
          @request.stub!(:sleep)              
        end

        it "should sleep for 1 second before each timeout" do
          @connection.stub!(:request).and_raise(Errno::ECONNREFUSED)        
          @request.should_receive(:sleep).with(1)
          perform_catching_errors
        end

        describe "with subsequent success" do

          it "should post the request 2 times" do
            @connection.should_receive(:request).with(@mock_post).exactly(1).times.ordered.and_raise(Errno::ECONNREFUSED)                
            @connection.should_receive(:request).with(@mock_post).exactly(1).times.ordered
            @request.perform           
          end   

          it "should return the response from the service" do
            @connection.should_receive(:request).with(@mock_post).exactly(1).times.ordered.and_raise(Errno::ECONNREFUSED)                
            @connection.should_receive(:request).with(@mock_post).exactly(1).times.ordered.and_return(@json_response)
            @request.perform.body.should == @json_response.body
          end
        end

        describe "with subsequent failure" do

          before :each do
            @connection.stub!(:request).and_raise(Errno::ECONNREFUSED)      
          end        

          it "should post the request 3 times (original + 2 retries)" do
            @connection.should_receive(:request).with(@mock_post).exactly(3).times.and_raise(Errno::ECONNREFUSED)        
            perform_catching_errors
          end      

          it "should raise an Voorhees::UnavailableError exception" do
            lambda {
              @request.perform
            }.should raise_error(Voorhees::UnavailableError)
          end
        end
      end
    end
  end
end



class MockNetHttp
  
  attr_accessor :connection
  
  def initialize(*args)
    @connection = mock(:connection)    
  end
  
  def start
    yield @connection
  end  
    
  def method_missing(*args)
    return self
  end
    
end
