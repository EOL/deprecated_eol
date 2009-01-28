# An evil fix
#
# The actual fix 
# has been pulled upstream into Rack
# but hasn't made it into the Rack gem yet, so we need this fix until the new gem is released
#
class Rack::MockRequest
  class << self

    alias env_for_without_content_length_fix env_for
    def env_for_with_content_length_fix uri = '', opts = {}
      env = env_for_without_content_length_fix uri, opts
      env['CONTENT_LENGTH'] ||= env['rack.input'].length
      env
    end
    alias env_for env_for_with_content_length_fix

  end
end
