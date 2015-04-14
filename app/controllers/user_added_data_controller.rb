class UserAddedDataController < ApplicationController

  layout 'basic'

  before_filter :check_authentication, only: [ :create, :edit, :update, :destroy ]
  before_filter :restrict_to_admins_and_master_curators # NOTE - this restriction should be removed when we release this feature, of course.
  before_filter :restrict_to_data_viewers

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
      log_action(:create)
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
      # TODO - second argument to constructor should be an I18n key for a human-readable error.
      raise EOL::Exceptions::SecurityViolation,
        "User with ID=#{current_user.id} does not have edit access to UserAddedData with ID=#{@user_added_data.id}"
    end
  end

  # PUT /user_added_data/:id
  def update
    delete_empty_metadata
    @user_added_data = UserAddedData.find(params[:id])
    unless current_user.can_update?(@user_added_data)
      # TODO - second argument to constructor should be an I18n key for a human-readable error.
      raise EOL::Exceptions::SecurityViolation,
        "User with ID=#{current_user.id} does not have edit access to UserAddedData with ID=#{@user_added_data.id}"
    end
    if @user_added_data.update_attributes(params[:user_added_data])
      flash[:notice] = I18n.t('user_added_data.update_successful')
      log_action(:update) unless @user_added_data.visibility_id == $invisible_global.id
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
    # TODO - second argument to constructor should be an I18n key for a human-readable error.
    raise EOL::Exceptions::SecurityViolation,
      "User with ID=#{current_user.id} does not have edit access to UserAddedData with ID=#{@user_added_data.id}" unless current_user.can_delete?(user_added_data)
    user_added_data.update_attributes({ deleted_at: Time.now })
    flash[:notice] = I18n.t('user_added_data.delete_successful')
    redirect_to taxon_data_path(user_added_data.taxon_concept_id)
  end

  private

  # Not just "empty" but also deafult values that we consider "empty".
  def delete_empty_metadata
    params[:user_added_data][:user_added_data_metadata_attributes].delete_if do |k,v|
      if v[:id].blank? && v[:predicate].blank? && v[:object].blank?
        true
      else
        case v[:predicate]
        when UserAddedDataMetadata::SUPPLIER_URI
          v[:object] == current_user.full_name # No need to add this; it's in the DB already.
        when UserAddedDataMetadata::SOURCE_URI
          v[:object].blank? || v[:object] == I18n.t('user_added_data.source_field_helper')
        when UserAddedDataMetadata::LICENSE_URI
          v[:object] == I18n.t(:license_none)
        when UserAddedDataMetadata::MEASUREMENT_UNIT_URI
          v[:object].blank?
        when I18n.t('user_added_data.new_field')
          true # They didn't add (or at least name) this one, just remove it.
        else
          false
        end
      end
    end
  end

  def convert_fields_to_uri
    add_uri_to_session(convert_field_to_uri(params[:user_added_data], :predicate))
    convert_field_to_uri(params[:user_added_data], :object)
    params[:user_added_data][:user_added_data_metadata_attributes].each do |index, meta|
      convert_field_to_uri(meta, :predicate)
      convert_field_to_uri(meta, :object)
    end
  end

  # NOTE - just passing in the field wasn't working (thought it would be by ref, but I guess not), so we need the
  # hash and the key:
  def convert_field_to_uri(hash, key)
    return unless hash[key]
    return if EOL::Sparql.is_uri?(hash[key])
    converted = convert_to_uri(hash[key])
    if converted.blank?
      # They want to create a new EOL-based URI:
      hash[key] = KnownUri.custom(hash[key], current_language).uri unless key == :object # Not for values.
    else
      hash[key] = converted
    end
    hash[key]
  end

  # NOTE that this only takes the first one it finds.
  def convert_to_uri(name)
    return nil unless TranslatedKnownUri.exists?(name: name, language_id: current_language.id)
    turi = TranslatedKnownUri.where(name: name, language_id: current_language.id).first
    return nil unless turi.known_uri && ! turi.known_uri.uri.blank?
    uri = turi.known_uri.uri
    uri
  end

  def add_uri_to_session(uri)
    session[:rec_uris] ||= []
    session[:rec_uris].unshift(uri)
    session[:rec_uris] = session[:rec_uris].uniq[0..7]
  end

  def log_action(method)
    CuratorActivityLog.create(
      user_id: current_user.id,
      changeable_object_type: ChangeableObjectType.user_added_data,
      target_id: @user_added_data.id,
      activity: Activity.send(method),
      taxon_concept_id: @user_added_data.taxon_concept_id
    )
  end

end
