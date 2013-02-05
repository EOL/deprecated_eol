class ForumsController < ApplicationController

  layout 'v2/forum'
  before_filter :allow_login_then_submit, :only => [ :create ]
  before_filter :restrict_to_admins, :only => [ :create, :destroy, :move_up, :move_down ]

  # GET /forum
  def index
  end

  def show
    @forum = Forum.find(params[:id])
  end

  def create
    forum_data = params[:forum]
    if session[:submitted_data]
      forum_data ||= session[:submitted_data][:forum]
      session.delete(:submitted_data)
    end
    @forum = Forum.new(forum_data)
    @forum.user_id = current_user.id
    if @forum.save
      flash[:notice] = 'Forum was added'
    else
      flash[:error] = 'Forum was not added'
      flash[:error] << " #{@forum.errors.full_messages.join('; ')}." if @forum.errors.any?
      redirect_to forums_path
      return
    end
    redirect_to forum_path(@forum)
  end

  def destroy
    @forum = Forum.find(params[:id])
    if @forum.forum_topics.count == 0
      @forum.destroy
      flash[:notice] = 'Forum was deleted'
    else
      flash[:error] = 'Forum was not empty'
    end
    redirect_to forums_path
  end

  def move_up
    @forum = Forum.find(params[:id])
    if @next_lowest = Forum.where("forum_category_id = #{@forum.forum_category_id} AND view_order < #{@forum.view_order}").order("view_order desc").limit(1).first
      new_view_order = @next_lowest.view_order
      @next_lowest.update_attributes(:view_order => @forum.view_order)
      @forum.update_attributes(:view_order => new_view_order)
      flash[:notice] = 'Forum was moved'
    else
      flash[:error] = 'Forum was not moved'
    end
    redirect_to forums_path
  end

  def move_down
    @forum = Forum.find(params[:id])
    if @next_highest = Forum.where("forum_category_id = #{@forum.forum_category_id} AND view_order > #{@forum.view_order}").order("view_order asc").limit(1).first
      new_view_order = @next_highest.view_order
      @next_highest.update_attributes(:view_order => @forum.view_order)
      @forum.update_attributes(:view_order => new_view_order)
      flash[:notice] = 'Forum was moved'
    else
      flash[:error] = 'Forum was not moved'
    end
    redirect_to forums_path
  end

end
