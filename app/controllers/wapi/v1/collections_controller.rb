module Wapi
  module V1
    class CollectionsController < ApplicationController
      respond_to :json
      before_filter :restrict_access, except: [:index, :show]
      before_filter :find_collection, only: [:update, :destroy]
      DEFAULT_ITEMS_NUMBER_PER_PAGE = 30

      def index
        respond_with Collection.where(published: true).paginate(page: params[:page] ||= 1, per_page: params[:per_page] ||= DEFAULT_ITEMS_NUMBER_PER_PAGE)
      end

      def show
        respond_with Collection.where(id: params[:id]).
          includes(:collection_items).first, items: true
      end

      def create
        if params[:collection]
          # And, of course, we expect the user to be pre-populated based on key:
          params[:collection][:users] = [@user]
          coll_items_params = params[:collection][:collection_items]? params[:collection].delete(:collection_items) : nil
        end
        ActiveRecord::Base.transaction do
          begin
            @collection = Collection.create!(params[:collection])
            collection_items = add_collection_items(coll_items_params) if coll_items_params
            @collection.save
            respond_with @collection.reload
          rescue Exception => e
            respond_with(@collection, status: :unprocessable_entity) do |format|
              format.json { render json: (I18n.t(:collection_create_failure) + e.to_s).to_json }
            end
            raise ActiveRecord::Rollback
          end
        end
      end

      def update
        if @collection.blank?
          respond_with do |format|
            format.json { render json: I18n.t("collection_not_existing", collection:params[:id]).to_json, status: :not_found }
          end
          return
        end
        head :unauthorized and return unless @user && @user.can_update?(@collection)
        ActiveRecord::Base.transaction do
          begin
            if params[:collection]
              if params[:collection][:collection_items]
              @collection.items.destroy_all
                params[:collection][:collection_items].each do |item|
                  collection_item = CollectionItem.create!( item.except!(:id, :updated_at, :created_at).merge(collection_id: @collection.id))
                end
              end
              @collection.update_attributes(params[:collection].except!(:id, :updated_at, :created_at, :collection_items).
               merge(collection_items_count: @collection.items.count))
              respond_with do |format|
                format.json { render json: @collection.to_json, status: :ok }
              end
            end
          rescue
            respond_with do |format|
              format.json { render json: (I18n.t("collection_update_failure", collection: @collection.id) + e.to_s).to_json, status: :ok }
            end
            raise ActiveRecord::Rollback
          end
        end
      end

      def destroy
        if @collection.blank?
           respond_with do |format|
          format.json { render json: I18n.t("collection_not_existing", collection:params[:id]).to_json, status: :not_found }
            end
          return
        end
        head :unauthorized and return unless @user && @user.can_update?(@collection)
        @collection.collection_items.destroy_all
        @collection.destroy
        respond_with do |format|
          format.json { render json: I18n.t("collection_removed", collection: @collection.id).to_json, status: :ok }
        end
      end

      private

      def add_collection_items(coll_items_params)
        collection_items = []
        coll_items_params.each do |item_params|
          raise EOL::Exceptions::InvalidCollectionItemType.new(I18n.t(:cannot_create_collection_item_from_class_error,
            klass: item_params["collected_item_type"])) if ! ['TaxonConcept', 'User', 'DataObject', 'Community', 'Collection'].include? item_params["collected_item_type"]
          item_params[:collection_id] = @collection.id
          item_params[:added_by_user_id] = @user.id
          collection_items << CollectionItem.create!(item_params)
        end
        @collection.collection_items = collection_items
        @collection.collection_items_count = collection_items.count
      end
      
      def find_collection
        @collection = Collection.find_by_id(params[:id])
      end

      # -H 'Authorization: Token token="ABCDEF12345"'
      # See also the request specs.
      def restrict_access
        authenticate_or_request_with_http_token do |token, options|
          @user = User.find_by_api_key(token)
        end
      end
    end
  end
end
