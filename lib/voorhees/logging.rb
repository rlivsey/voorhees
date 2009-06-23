module Voorhees
  def self.debug(message)
    Voorhees::Config[:logger].debug("VOORHEES: #{message}")
  end
end