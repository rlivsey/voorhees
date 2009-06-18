module Voorhees 
  
  class Response
    
    attr_reader :parsed, :body, :code, :message, :headers
    
    def initialize(parsed, body, code, message, headers={})
      @parsed = parsed
      @body     = body
      @code     = code.to_i
      @message  = message
      @headers  = headers
    end
    
  end
  
end