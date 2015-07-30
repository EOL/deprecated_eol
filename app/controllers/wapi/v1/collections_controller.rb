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
        
        # @user = User.find_by_api_key("AB12345") #delete this line , it's just for testing
        ActiveRecord::Base.transaction do
          begin
            if params[:collection]
              if params[:collection][:collection_items]
                # Rails wants "collection_items_attributes", which it would use if
                # generating the form itself, but that's lame in the context of 3rd
                # party input JSON, so I update it here:
                params[:collection][:collection_items_attributes] =
                 params[:collection].delete(:collection_items)
                params[:collection][:collection_items_attributes].each do |hash|
                  hash[:added_by_user_id] = @user.id
                end
              end
              # And, of course, we expect the user to be pre-populated based on key:
              params[:collection][:users] = [@user]
            end
            @collection = Collection.create!(params[:collection].merge(collection_items_count: params[:collection][:collection_items_attributes].count))
            @collection.save
            @collection.users = [@user]
            respond_with @collection.reload
          rescue
            respond_with(@collection, status: :unprocessable_entity) do |format|
              format.json { render json: { errors: @collection.errors.full_messages }.to_json }
            end
            raise ActiveRecord::Rollback
        end
        end
      end

      def update

        # @user = User.find_by_api_key("AB12345") #delete this line , it's just for testing
        if @collection.blank?
          respond_with do |format|
            format.json { render json: I18n.t("collection_not_existing", collection:params[:id]).to_json, status: :ok }
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
                  collection_item = CollectionItem.create( item.except!(:id, :updated_at, :created_at).merge(collection_id: @collection.id))
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
              format.json { render json: I18n.t("collection_update_failure", collection: @collection.id).to_json, status: :ok }
            end
            raise ActiveRecord::Rollback
          end
        end
      end

      def destroy
        # @user = User.find_by_api_key("AB12345") #delete this line , it's just for testing
        if @collection.blank?
           respond_with do |format|
          format.json { render json: I18n.t("collection_not_existing", collection:params[:id]).to_json, status: :ok }
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
