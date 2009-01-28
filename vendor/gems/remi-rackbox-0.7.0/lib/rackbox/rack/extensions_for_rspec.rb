# some more Rack extensions to help when testing
class Rack::MockResponse

  # these methods help with RSpec specs so we can ask things like:
  #
  #   request('/').should be_successful
  #   request('/').should be_redirect
  #   request('/').should be_error
  #

  def success?
    self.status.to_s.start_with?'2' # 200 status codes are successful
  end

  def redirect?
    self.status.to_s.start_with?'3' # 300 status codes are redirects
  end

  def client_error?
    self.status.to_s.start_with?'4' # 400 status codes are client errors
  end

  def server_error?
    self.status.to_s.start_with?'5' # 500 status codes are server errors
  end

  def error?
    self.status.to_s.start_with?('4') || self.status.to_s.start_with?('5') # 400 & 500 status codes are errors
  end

end
