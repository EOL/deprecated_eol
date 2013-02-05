class Forums::TopicsController < ForumsController

  skip_before_filter :restrict_to_admins
  before_filter :allow_login_then_submit, :only => [ :create ]

  def show
    @topic = ForumTopic.find(params[:id])
  end

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
      flash[:notice] = 'Topic was added'
    else
      flash[:error] = 'Topic was not added'
      flash[:error] << " #{@topic.errors.full_messages.join('; ')}." if @topic.errors.any?
      redirect_to forum_path(topic_data[:forum_id])
      return
    end
    redirect_to forum_topic_path(@topic.forum, @topic)
  end

  def destroy
    @topic = ForumTopic.find(params[:id])
    if @topic.forum_posts.count == 0
      @topic.destroy
      flash[:notice] = 'Topic was deleted'
    else
      flash[:error] = 'Topic was not empty'
    end
    redirect_to forum_path(@topic.forum)
  end

end
