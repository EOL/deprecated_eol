RSpec.configure do |config|
  config.include Models::CacheHelpers, type: :model
end
