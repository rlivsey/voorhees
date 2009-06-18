module Voorhees
  class Error < ::StandardError; end
  class ParameterRequiredError < Error; end
  class NotFoundError < Error; end
  class TimeoutError < Error; end
  class UnavailableError < Error; end
end