module Voorhees
  class Error < ::StandardError; end
  class ParameterMissingError < Error; end
  class NotFoundError < Error; end
  class TimeoutError < Error; end
  class UnavailableError < Error; end
  class ParseError < Error; end  
end