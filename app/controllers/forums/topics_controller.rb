class Forums::TopicsController < ForumsController

  skip_before_filter :restrict_to_admins
  before_filter :allow_login_then_submit, :only => [ :create ]

  # GET /forums/:forum_id/topics/:id
  def show
    params[:page] ||= 1
    params[:page] = 1 if params[:page].to_i < 1
    @topic = ForumTopic.find(params[:id])
    if params[:page].to_i > @topic.forum_posts.last.page_in_topic
      params[:page] = @topic.forum_posts.last.page_in_topic
    end
    @posts = @topic.forum_posts.paginate(:page => params[:page], :per_page => ForumTopic::POSTS_PER_PAGE)
    ForumPost.preload_associations(@posts, [ :user, :forum_topic ])
  end

  # POST /forums/:forum_id/topics
  def create
    topic_data = params[:forum_topic]
    if session[:submitted_data]
      topic_data ||= session[:submitted_data][:forum_topic]
      session.delete(:submitted_data)
    end
    topic_data[:title] = topic_data[:forum_posts_attributes]["0"][:subject]
    topic_data[:user_id] = current_user.id
    topic_data[:forum_posts_attributes]["0"][:user_id] = current_user.id
    @topic = ForumTopic.new(topic_data)
    if @topic.save
      flash[:notice] = I18n.t('forums.topics.create_successful')
    else
      flash[:error] = I18n.t('forums.topics.create_failed')
      flash[:error] << " #{@topic.errors.full_messages.join('; ')}." if @topic.errors.any?
      redirect_to forum_path(topic_data[:forum_id])
      return
    end
    redirect_to forum_topic_path(@topic.forum, @topic)
  end

  # DELETE /forums/:forum_id/topics/:id
  def destroy
    @topic = ForumTopic.find(params[:id])
    if @topic.forum_posts.count == 0
      @topic.destroy
      flash[:notice] = I18n.t('forums.topics.delete_successful')
    else
      flash[:error] = I18n.t('forums.topics.delete_failed')
    end
    redirect_to forum_path(@topic.forum)
  end

end
