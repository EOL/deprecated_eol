class UserAddedDataController < ApplicationController

  # POST /user_added_data
  def create
    # TODO - we can move the TC id into the UAD params, now.
    @user_added_data = UserAddedData.new(params[:user_added_data].reverse_merge(user: current_user))
    if @user_added_data.save
      flash[:notice] = I18n.t(:added_data)
    else
      # NOTE - we can't just use validation messages quite yet, since it's created in another controller. :\
      if @user_added_data.errors.any?
        flash[:error] = I18n.t(:error_unable_to_create_user_data,
                               errors: @user_added_data.errors.full_messages.to_sentence)
      end
      redirect_to taxon_data_path(@user_added_data.taxon_concept_id)
      return
    end
    redirect_to taxon_data_path(@user_added_data.taxon_concept_id)
  end

end
