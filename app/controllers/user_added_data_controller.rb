class UserAddedDataController < ApplicationController

  # POST /user_added_data
  def create
    # TODO - we can move the TC id into the UAD params, now.
    taxon_concept_id = params[:taxon_concept_id]
    @user_added_data = UserAddedData.new(
      params[:user_added_data].reverse_merge(
        taxon_concept_id: taxon_concept_id,
        user: current_user
      )
    )
    if @user_added_data.save
      # TODO - I18n...
      flash[:notice] = "Create succeeded"
    else
      # TODO - I18n...
      flash[:error] = "Create failed:"
      flash[:error] << " #{@user_added_data.errors.full_messages.to_sentence}." if @user_added_data.errors.any?
      redirect_to taxon_data_path(taxon_concept_id)
      return
    end
    redirect_to taxon_data_path(taxon_concept_id)
  end

end
