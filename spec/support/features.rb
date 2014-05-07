require_relative 'features/session_helpers'
require_relative 'features/api_helpers'

RSpec.configure do |config|
  config.include Features::SessionHelpers, type: :feature
  config.include Features::ApiHelpers, type: :feature
end
