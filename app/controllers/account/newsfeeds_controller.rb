class Account::NewsfeedsController < AccountController

  layout 'v2/account'

  def show
    @user = current_user
  end

end
