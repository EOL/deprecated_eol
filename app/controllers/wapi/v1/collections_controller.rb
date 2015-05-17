module Wapi
  module V1
    class CollectionsController < ApplicationController
      respond_to :json
      before_filter :restrict_access, except: [:index, :show]
      before_filter :find_collection, only: [:update, :destroy]

      def index
        # TODO: pagination! This would be HUGE.
        respond_with Collection.where(published: true).all.take(10)
      end

      def show
        respond_with Collection.where(id: params[:id]).
          includes(:collection_items).first, items: true
      end

      def create
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
        @collection = Collection.create(params[:collection])
        if @collection.save
          @collection.users = [@user]
          respond_with @collection
        else
          respond_with(@collection, status: :unprocessable_entity) do |format|
            format.json { render json: { errors: @collection.errors.full_messages }.to_json }
          end
        end
      end

      def update
        head :unauthorized and return unless @user && @user.can_update?(@collection)
        ActiveRecord::Base.transaction do
          begin
            if params[:collection_items]
              params[:collection_items].each do |item|
                (@collection.collection_items.select{|col_item| col_item[:id] == item[:id].to_i}.first).update_attributes!(item.except!(:id, :updated_at, :created_at))
              end
            end
            @collection.update_attributes!(params[:collection].except!(:id, :updated_at, :created_at))
            respond_with do |format|
              format.json { render json: @collection.to_json, status: :ok }
            end
          rescue Exception => e
            respond_with do |format|
              format.json { render json: I18n.t("collection_update_failure", collection: @collection.id).to_json, status: :ok }
            end
            raise ActiveRecord::Rollback
          end
        end
      end

      def destroy
        #@user = User.find(74)
        head :unauthorized and return unless @user && @user.can_update?(@collection)
        CollectionItem.destroy(@collection.collection_items.map{|item| item.id})
        @collection.destroy
        respond_with do |format|
          format.json { render json: I18n.t("collection_removed", collection: @collection.id).to_json, status: :ok }
        end
      end

      private

      def find_collection
        @collection = Collection.find(params[:id])
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
