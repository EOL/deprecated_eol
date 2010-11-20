class UserIgnoredDataObjectsController < ApplicationController
  def index
    dato_ids = current_user.ignored_data_objects(DataType.image.id.to_i).collect{|d| d.id}
    @ignored_images = DataObject.details_for_objects(dato_ids, :skip_refs => true, :add_common_names => true, :add_comments => true, :sort => 'id desc')
  end
  
  def create
    @data_object = DataObject.find(params[:data_object_id])
    UserIgnoredDataObject.create(:user => current_user, :data_object => @data_object)
  end

  def destroy
    @data_object = DataObject.find(params[:data_object_id])
    UserIgnoredDataObject.find_by_user_id_and_data_object_id(current_user.id, @data_object.id).destroy
    @div_id = params[:div_id]
    respond_to do |format|
      format.js
    end
    
  end
end
