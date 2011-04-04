class UsersController < ApplicationController

  layout 'main'

  def show
    @user = User.find(params[:id])
    @feed_item = FeedItem.new(:feed_id => @user.id, :feed_type => @user.class.name)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # PUT /user/1
  # PUT /user/1.json
  def update
    @user = User.find(params[:id])
    anchor = nil
    if params[:generate_api_key]
      params[:user] = {} unless params[:user]
      params[:user][:api_key] = User.generate_key
      anchor = "profile_api_key"
    end
    respond_to do |format|
      worked = false
      if current_user.id == @user.id
        alter_current_user do # You MUST use this in order to preserve the cached version of the user!
          worked = @user.update_attributes(params[:user])
        end
      end
      if worked
        flash[:notice] = I18n.t("user_var__user_username_was_su", :var__user_username => @user.username)
        format.html { redirect_to :controller => :account, :action => :profile, :anchor => anchor }
        format.json  { render @user.to_json } 
      else
        flash[:error] = I18n.t("user_var__user_username_was_no", :var__user_username => @user.username)
        format.html { render :controller => :account, :action => :profile }
        format.json  { render @user.errors.to_json, :status => :unprocessable_entity }
      end
    end
  end

end
