class UserAddedDataController < ApplicationController

  layout 'v2/basic'

  # Doesn't seem to work unless it's here as WELL as taxon/data.
  autocomplete :known_uri, :uri
  autocomplete :translated_known_uri, :name

  # POST /user_added_data
  def create
    delete_empty_metadata
    convert_fields_to_uri
    # TODO - fix this later:
    type = params[:user_added_data].delete(:subject_type)
    raise "I don't know anything about #{type}, can't find one." unless type == 'TaxonConcept'
    subject = TaxonConcept.find(params[:user_added_data].delete(:subject_id))
    @user_added_data = UserAddedData.new(params[:user_added_data].reverse_merge(user: current_user,
                                                                                subject: subject))
    if @user_added_data.save
      flash[:notice] = I18n.t('user_added_data.create_successful')
    else
      # NOTE - we can't just use validation messages quite yet, since it's created in another controller. :\
      if @user_added_data.errors.any?
        flash[:error] = I18n.t('user_added_data.create_failed',
                               errors: @user_added_data.errors.full_messages.to_sentence)
      end
    end
    redirect_to taxon_data_path(@user_added_data.taxon_concept_id)
  end

  # GET /user_added_data/:id/edit
  def edit
    @user_added_data = UserAddedData.find(params[:id])
    unless current_user.can_update?(@user_added_data)
      raise EOL::Exceptions::SecurityViolation,
        "User with ID=#{current_user.id} does not have edit access to UserAddedData with ID=#{@user_added_data.id}"
    end
  end

  # PUT /user_added_data/:id
  def update
    delete_empty_metadata
    @user_added_data = UserAddedData.find(params[:id])
    unless current_user.can_update?(@user_added_data)
      raise EOL::Exceptions::SecurityViolation,
        "User with ID=#{current_user.id} does not have edit access to UserAddedData with ID=#{@user_added_data.id}"
    end
    if @user_added_data.update_attributes(params[:user_added_data])
      flash[:notice] = I18n.t('user_added_data.update_successful')
    else
      flash[:error] = I18n.t('user_added_data.update_failed',
                             errors: @user_added_data.errors.full_messages.to_sentence)
      render :edit
      return
    end
    redirect_to taxon_data_path(@user_added_data.subject)
  end

  # DELETE /user_added_data/:id
  def destroy
    user_added_data = UserAddedData.find(params[:id])
    raise EOL::Exceptions::SecurityViolation,
      "User with ID=#{current_user.id} does not have edit access to UserAddedData with ID=#{@user_added_data.id}" unless current_user.can_delete?(user_added_data)
    user_added_data.update_attributes({ :deleted_at => Time.now })
    flash[:notice] = I18n.t('user_added_data.delete_successful')
    redirect_to taxon_data_path(user_added_data.taxon_concept_id)
  end

  private

  def delete_empty_metadata
    params['user_added_data']['user_added_data_metadata_attributes'].delete_if{ |k,v| v['id'].blank? && v['predicate'].blank? && v['object'].blank? }
  end

  def convert_fields_to_uri
    convert_field_to_uri(params[:user_added_data], :predicate)
    convert_field_to_uri(params[:user_added_data], :object)
    convert_field_to_uri(params[:user_added_data][:user_added_data_metadata_attributes][0], :predicate)
    convert_field_to_uri(params[:user_added_data][:user_added_data_metadata_attributes][0], :object)
  end

  # NOTE - just passing in the field wasn't working (thought it would be by ref, but I guess not), so we need the hash and the key:
  def convert_field_to_uri(hash, key)
    return unless hash[key]
    converted = convert_to_uri(hash[key])
    hash[key] = converted unless converted.blank?
  end

  # NOTE that this only takes the first one it finds.
  def convert_to_uri(name)
    return nil unless TranslatedKnownUri.exists?(name: name, language_id: current_language.id)
    TranslatedKnownUri.where(name: name, language_id: current_language.id).first.known_uri.uri
  end

end
