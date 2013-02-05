class Forums::PostsController < ForumsController

  skip_before_filter :restrict_to_admins
  before_filter :allow_login_then_submit, :only => [ :create ]
  before_filter :check_authentication, :except => [ :show, :new, :reply ]

  def show
    @post = ForumPost.find(params[:id])
    redirect_to forum_topic_path(@post.forum_topic.forum, @post.forum_topic, :anchor => "post_#{@post.id}")
  end

  def create
    topic_id = params[:topic_id]
    post_data = params[:forum_post]
    if session[:submitted_data]
      post_data ||= session[:submitted_data][:forum_post]
      topic_id ||= session[:submitted_data][:topic_id]
      session.delete(:submitted_data)
    end
    @topic = ForumTopic.find(topic_id)
    @post = ForumPost.new(post_data)
    @post.user_id = current_user.id
    if @post.save
      flash[:notice] = 'Post was added'
    else
      flash[:error] = 'Post was not added'
      flash[:error] << " #{@post.errors.full_messages.join('; ')}." if @post.errors.any?
    end
    redirect_to forum_topic_path(@topic.forum, @topic, :anchor => "post_#{@post.id}")
  end

  def new
    @reply_to_post = ForumPost.find(params[:reply_to]) rescue nil
    @topic = @reply_to_post.forum_topic
  end

  def reply
    @reply_to_post = ForumPost.find(params[:id]) rescue nil
    @topic = @reply_to_post.forum_topic
    render :new
  end

  def edit
    @post = ForumPost.find(params[:id])
    raise EOL::Exceptions::SecurityViolation,
      "User with ID=#{current_user.id} does not have edit access to ForumPost with ID=#{@post.id}" unless current_user.can_update?(@post)
  end

  def update
    @post = ForumPost.find(params[:id])
    raise EOL::Exceptions::SecurityViolation,
      "User with ID=#{current_user.id} does not have edit access to ForumPost with ID=#{@post.id}" unless current_user.can_update?(@post)
    if @post.update_attributes(params[:forum_post])
      flash[:notice] = 'Post was added'
    else
      flash[:error] = 'Post was not added'
      flash[:error] << " #{@post.errors.full_messages.join('; ')}." if @post.errors.any?
      render :edit
      return
    end
    redirect_to forum_topic_path(@post.forum_topic.forum, @post.forum_topic, :anchor => "post_#{@post.id}")
  end

  def destroy
    @post = ForumPost.find(params[:id])
    raise EOL::Exceptions::SecurityViolation,
      "User with ID=#{current_user.id} does not have edit access to ForumPost with ID=#{@post.id}" unless current_user.can_delete?(@post)
    if @post.topic_starter? && @post.forum_topic.forum_posts.count > 1
      flash[:error] = 'Topic is not empty'
    else
      if @post.forum_topic.forum_posts.count == 1
        @post.forum_topic.destroy
        @post.destroy
        flash[:notice] = 'Post and Topic were deleted'
        redirect_to forum_path(@post.forum_topic.forum)
        return
      else
        @post.destroy
        flash[:notice] = 'Post was deleted'
      end
    end
    redirect_to forum_topic_path(@post.forum_topic.forum, @post.forum_topic)
  end

end
