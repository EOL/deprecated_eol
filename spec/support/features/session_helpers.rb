module Features
  module SessionHelpers

      def login_as(user, options = {})
        if user.is_a? User # let us pass a newly created user (with an entered_password)
          options.reverse_merge!(:username => user.username, :password => user.entered_password)
        elsif user.class.name == 'User'
          # This is a weird situation that can arise when using Zeus or guard. Looks like classes don't maintain identity over
          # time. Sigh.
          raise "** ERROR: your classes are screwed up. user.is_a?(User) is false. That's bad. Restart your environment."
        elsif user.is_a? Hash
          options = options.merge(user)
        end
        visit logout_path
        visit login_path
        options[:password] = 'test password' if options[:password].blank?
        fill_in "session_username_or_email", :with => options[:username]
        fill_in "session_password", :with => options[:password]
        check("remember_me") if options[:remember_me] && options[:remember_me].to_i != 0
        click_button I18n.t("helpers.submit.session.create")
        page
      end

  end
end

