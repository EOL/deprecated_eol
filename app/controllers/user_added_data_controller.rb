class UserAddedDataController < ApplicationController

  # POST /user_added_data
  def create
    taxon_concept_id = params[:taxon_concept_id]
    params[:user_added_data][:subject] = "<http://eol.org/pages/" + taxon_concept_id + ">"
    @user_added_data = UserAddedData.new(params[:user_added_data])
    @user_added_data.user_id = current_user.id
    if @user_added_data.save
      flash[:notice] = "Create succeeded"
    else
      flash[:error] = "Create failed"
      flash[:error] << " #{@user_added_data.errors.full_messages.join('; ')}." if @user_added_data.errors.any?
      redirect_to taxon_data_path(taxon_concept_id)
      return
    end
    redirect_to taxon_data_path(taxon_concept_id)
  end

end
