class CommentsController < ApplicationController

  layout :comments_layout
  before_filter :allow_login_then_submit, :only => [:create]

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

    if @comment.save
      flash[:notice] = I18n.t(:comment_added_notice)
      auto_collect(@comment.parent)
    else
      flash[:error] = I18n.t(:comment_not_added_error)
      flash[:error] << " #{@comment.errors.full_messages.join('; ')}." if @comment.errors.any?
    end
    redirect_back_or_default
  end

  def edit
    @page_title = I18n.t("edit_comment")
    store_location(referred_url) if request.get?
    @comment = Comment.find(params[:id])
  end

  def update
    @comment = Comment.find(params[:id])
    if @comment.update_attributes(params[:comment])
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t("the_comment_was_successfully_updated")
          redirect_back_or_default(url_for(:action=>'index'))
        end
        format.js do
          render :partial => 'activity_logs/comment', :locals => { :item => @comment, :truncate_comments => false }
        end
      end
    else
      render :action => 'edit'
    end
  end

  def destroy
    (redirect_to referred_url;return) unless params[:action] == "destroy"
    @comment = Comment.find(params[:id])
    if @comment.update_attributes(:deleted => 1)
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t("the_comment_was_successfully_deleted")
          redirect_to referred_url
        end
        format.js do
          render :partial => 'activity_logs/comment', :locals => { :item => @comment, :truncate_comments => false }
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
end
