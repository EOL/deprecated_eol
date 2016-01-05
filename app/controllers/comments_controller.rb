class CommentsController < ApplicationController

  layout :comments_layout
  before_filter :allow_login_then_submit, only: [:create]
  before_filter :allow_modify_comments, only: [:edit, :update, :destroy]

  # NOTE - this was written, sadly, for data only. If you want this to do more, you'll need to re-write it.
  def index
    @parent = DataPointUri.find(params[:data_point_uri_id])
    @page_title = I18n.t(:comments_page_title, parent: @parent.summary_name)
  end

  # POST /comments
  def create
    comment_data = params[:comment] unless params[:comment].blank?
    return_to = params[:return_to] unless params[:return_to].blank?
    if session[:submitted_data]
      comment_data ||= session[:submitted_data][:comment]
      return_to ||= session[:submitted_data][:return_to]
      session.delete(:submitted_data)
    end

    @comment = Comment.new(comment_data)
    @comment.user_id = current_user.id
    current_user_is_curator = current_user.is_curator?
    @comment.from_curator = current_user_is_curator.blank? ? false : true

    return_to ||= link_to_item(@comment.parent) rescue nil
    store_location(return_to)

    if @comment.same_as_last?
      flash[:notice] = I18n.t(:duplicate_comment_warning)
    elsif @comment.spammy?
      flash[:notice] = I18n.t(:error_violates_tos)
    elsif @comment.save
      flash[:notice] = I18n.t(:comment_added_notice)
      auto_collect(@comment.parent)
    else
      flash[:error] = I18n.t(:comment_not_added_error)
      flash[:error] << " #{@comment.errors.full_messages.join('; ')}." if @comment.errors.any?
    end

    respond_to do |format|
      format.html do
        redirect_back_or_default
      end
      format.js do
        # NOTE - At the moment, this is ONLY being done on the data tab!  The JS will have to be re-written if we do it
        # elsewhere...
        convert_flash_messages_for_ajax
      end
    end
  end

  # GET /comments/:id/edit
  def edit
    # @comment set in before_filter :allow_modify_comments
    actual_date = params[:actual_date]
    actual_date ||= false
    respond_to do |format|
      format.html do
        return access_denied unless current_user.can_update?(@comment)
        store_location(referred_url) if request.get?
        @page_title = I18n.t("edit_comment")
        render :edit
      end
      format.js do
        if current_user.can_update?(@comment)
          render partial: 'comments/edit', locals: { comment: @comment, actual_date: actual_date }
        else
          render text: I18n.t(:comment_edit_by_javascript_not_authorized_error)
        end
      end
    end
  end

  # PUT /comments/:id
  def update
    # @comment set in before_filter :allow_modify_comments
    actual_date = params[:actual_date]
    actual_date ||= false
    if current_user.newish? && params[:comment][:body] =~ EOL.spam_re
      format.html do
        flash[:error] = I18n.t(:error_violates_tos)
        render action: 'edit'
      end
      format.js do
        render text: I18n.t(:error_violates_tos)
      end
    end
    if @comment.update_attributes(params[:comment])
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t(:the_comment_was_successfully_updated)
          redirect_to params[:return_to] || url_for(action: 'index'), status: :moved_permanently
        end
        format.js do
          render partial: 'activity_logs/comment', locals: { item: @comment, actual_date: actual_date }
        end
      end
    else
      respond_to do |format|
        format.js { render text: I18n.t(:comment_not_updated_error) }
        format.html do
          flash[:error] = I18n.t(:comment_not_updated_error)
          render action: 'edit'
        end
      end
    end
  end

  # DELETE /comments/:id
  def destroy
    # @comment set in before_filter :allow_modify_comments
    actual_date = params[:actual_date]
    actual_date ||= false
    if @comment.update_attributes(deleted: 1)
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t(:the_comment_was_successfully_deleted)
          redirect_to params[:return_to] || referred_url
        end
        format.js do
          render partial: 'activity_logs/comment', locals: { item: @comment, truncate_comments: false, actual_date: actual_date }
        end
      end
    else
      respond_to do |format|
        format.js { render text: I18n.t(:comment_not_deleted_error) }
        format.html do
          flash[:error] = I18n.t(:comment_not_deleted_error)
          redirect_to params[:return_to] || referred_url
        end
      end
    end
  end

private

  def comments_layout
    # No layout for Ajax calls.
    return false if request.xhr?
    case action_name
    when 'update', 'edit'
      'basic'
    when 'index'
      'data_comments'
    end
  end

  def allow_modify_comments
    @comment = Comment.find(params[:id])
    return access_denied if @comment.deleted?
    case action_name
    when 'update', 'edit'
      return access_denied unless current_user.can_update?(@comment)
    when 'destroy'
      return access_denied unless current_user.can_delete?(@comment)
    end
  end

end
