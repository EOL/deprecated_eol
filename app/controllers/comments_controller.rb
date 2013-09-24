class CommentsController < ApplicationController

  layout :comments_layout
  before_filter :allow_login_then_submit, :only => [:create]
  before_filter :allow_modify_comments, :only => [:edit, :update, :destroy]

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

    store_location(return_to)

    if @comment.same_as_last?
      flash[:notice] = I18n.t(:duplicate_comment_warning)
    elsif @comment.save
      flash[:notice] = I18n.t(:comment_added_notice)
      if $STATSD
        $STATSD.increment 'comments'
      end
      auto_collect(@comment.parent)
    else
      flash[:error] = I18n.t(:comment_not_added_error)
      flash[:error] << " #{@comment.errors.full_messages.join('; ')}." if @comment.errors.any?
    end
    redirect_back_or_default
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
          render :partial => 'comments/edit', :locals => { :comment => @comment, :actual_date => actual_date }
        else
          render :text => I18n.t(:comment_edit_by_javascript_not_authorized_error)
        end
      end
    end
  end

  # PUT /comments/:id
  def update
    # @comment set in before_filter :allow_modify_comments
    actual_date = params[:actual_date]
    actual_date ||= false
    if @comment.update_attributes(params[:comment])
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t(:the_comment_was_successfully_updated)
          redirect_to params[:return_to] || url_for(:action=>'index'), :status => :moved_permanently
        end
        format.js do
          render :partial => 'activity_logs/comment', :locals => { :item => @comment, :actual_date => actual_date }
        end
      end
    else
      respond_to do |format|
        format.js { render :text => I18n.t(:comment_not_updated_error) }
        format.html do
          flash[:error] = I18n.t(:comment_not_updated_error)
          render :action => 'edit'
        end
      end
    end
  end

  # DELETE /comments/:id
  def destroy
    # @comment set in before_filter :allow_modify_comments
    actual_date = params[:actual_date]
    actual_date ||= false
    if @comment.update_attributes(:deleted => 1)
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t(:the_comment_was_successfully_deleted)
          redirect_to params[:return_to] || referred_url
        end
        format.js do
          render :partial => 'activity_logs/comment', :locals => { :item => @comment, :truncate_comments => false, :actual_date => actual_date }
        end
      end
    else
      respond_to do |format|
        format.js { render :text => I18n.t(:comment_not_deleted_error) }
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
      'v2/basic'
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
