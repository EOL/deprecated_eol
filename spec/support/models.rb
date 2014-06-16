require_relative 'models/cache_helpers'
require_relative 'models/stdout_helpers'

RSpec.configure do |config|
  config.include Models::CacheHelpers, type: :model
  config.include Models::StdoutHelpers, type: :model
end
