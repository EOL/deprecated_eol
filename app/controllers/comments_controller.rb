class CommentsController < ApplicationController

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

end
