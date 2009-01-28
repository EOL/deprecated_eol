# Custom RSpec matchers
module RackBox::Matchers
  def self.included base
    
    # this should really just be matcher(:foo){ ... }
    # but there's a bit of other meta logic to deal with here
    Object.send :remove_const, :RedirectTo if defined? RedirectTo
    undef redirect_to if defined? redirect_to

    # the actual matcher logic
    matcher(:redirect_to, base) do |response, url|
      return false unless response['Location']
      response['Location'] == url
    end

  end
end
