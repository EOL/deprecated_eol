class UsersController < ApplicationController

  layout 'main'

  def show
    @user = User.find(params[:id])

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
        flash[:notice] = "User #{@user.username} was successfully updated."
        format.html { redirect_to :controller => :account, :action => :profile, :anchor => anchor }
        format.json  { render @user.to_json } 
      else
        flash[:error] = "User #{@user.username} was not updated."
        format.html { render :controller => :account, :action => :profile }
        format.json  { render @user.errors.to_json, :status => :unprocessable_entity }
      end
    end
  end

end
