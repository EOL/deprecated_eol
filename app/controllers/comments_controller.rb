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
    @comment.from_curator = current_user.is_curator?

    store_location(return_to)

    if @comment.save
      flash[:notice] = I18n.t(:comment_added_notice)
      auto_collect
    else
      flash[:error] = I18n.t(:comment_not_added_error)
      flash[:error] << " #{@comment.errors.full_messages.join('; ')}." if @comment.errors.any?
    end
    redirect_back_or_default
  end

end

private

  # Ensure that the user has this in their watch_colleciton, so they will get replies in their newsfeed:
  def auto_collect
    watchlist = current_user.watch_collection
    logger.error "*" * 234
    logger.error "** AUTO_COLLECT"
    collection_item = CollectionItem.find_by_collection_id_and_object_id_and_object_type(
      watchlist.id,
      @comment.parent_id,
      @comment.parent_type
    )
    if collection_item.nil?
      logger.error "** NOT FOUND"
      collection_item = begin # No care if this fails.
        CollectionItem.create(
          :annotation => I18n.t(:user_left_comment_on_date, :username => current_user.short_name, :date => I18n.l(Date.today)),
          :object => @comment.parent,
          :collection_id => watchlist.id
        )
        CollectionActivityLog.create(:collection => watchlist, :user => current_user,
                                     :activity => Activity.collect, :collection_item => collection_item)
      rescue => e
        logger.error "** ERROR COLLECTING: #{e.message} FROM #{e.backtrace.first}"
        nil
      end
      if collection_item
        logger.error "** COLLECTED, FLASHING"
        flash[:notice] ||= ''
        flash[:notice] += ' '
        flash[:notice] += I18n.t(:item_added_to_watch_collection_notice,
                                 :collection_name => self.class.helpers.link_to(watchlist.name,
                                                                                collection_path(watchlist)),
                                 :item_name => @comment.parent.summary_name)
      end
    end
    logger.error "** EXIT COLLECT"
  end
