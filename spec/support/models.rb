RSpec.configure do |config|
  config.include Models::CacheHelpers, type: :model
  config.include Models::StdoutHelpers, type: :model
end
