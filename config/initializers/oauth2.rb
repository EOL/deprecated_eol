# This is required to parse facebook user's profile information
OAuth2::Response.register_parser(:text, 'text/plain') do |body|
  key, value = body.split('=')
  {key => value}
end
