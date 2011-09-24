## Head mobile controller.
## All mobile app controllers must hereditate from this.
class Mobile::MobileController < ApplicationController
  layout "#{RAILS_ROOT}/app/views/layouts/v2/mobile/application.html.haml"

end
