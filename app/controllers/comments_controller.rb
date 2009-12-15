class CommentsController < ApplicationController
  layout 'main'

  helper :taxa

  make_resourceful do
    actions :all, :except => :edit
    belongs_to :data_object, :taxon_concept

    before :create do
      current_object.user_id = current_user.id
    end

    after :create do
      # current_object.visible_at = Time.now # moved to model, before_create - gets set automatically on create (but on on update / etc, so it can be changed / hidden)
      current_object.save
    end

    response_for :create do |format|
      format.html { redirect_to objects_path }
      format.js do
        params[:page] = (parent_object.visible_comments(current_user).length.to_f / Comment.per_page.to_f).ceil
        prepare_index
        render :update do |page|
          page.replace_html params[:body_div_name].blank? ? 'commentsContain' : params[:body_div_name], {:partial => 'index.js.erb',
            :locals => {:body_div_name => params[:body_div_name].blank? ? 'commentsContain' : params[:body_div_name]},
            :object => [parent_object, current_object] }
        end
      end
    end

    before :index do
      raise "Comments are only meaningful when associated with an object" unless parent?
      prepare_index
    end

    response_for :index do |format|
      format.html { } # usual affair
      format.js { render :partial => 'index',
                         :locals => {:body_div_name => params[:body_div_name].blank? ? 'commentsContain' : params[:body_div_name]} }
    end

  end

  def prepare_index
    @comment = Comment.new(:user => current_user)
    @parent = parent_object
    @type   = :image if parent_name == 'data_object' and @parent.image? 
    @type   = :text  if parent_name == 'data_object' and not @parent.data_objects_table_of_contents.empty?
    @type   = :taxon if parent_name == 'taxon_concept'
    @slim_container = true # So, this will re-arrange some of the view, based on which format we have to play with.
    if @type == :image
      @title_label    = 'above image'
      @title = '' # @parent.description.blank? ? 'Above Image' : @parent.description
      @current_params = "data_object_id=#{params[:data_object_id]}"
    elsif @type == :text
      @title          = '' # "#{@parent.authors.collect {|a| a.full_name}.join(',<br />')}"
      @title_label    = 'above text'
      #@title_label   += ' by' unless @title.empty?
      @current_params = "data_object_id=#{params[:data_object_id]}"
    elsif @type == :taxon
      @title          = @parent.title
      @slim_container = false
    end
  end

#show/hide comment
  def remove
    current_user.unvet current_object 
    render :partial => 'remove'
  end

  def make_visible
    current_user.vet current_object 
    render :partial => 'make_visible'
  end
  
private
  def current_comments
    current_comments = []
    if parent_name == 'data_object'
      current_comments = parent_object.all_comments
    else #"taxon_concept"
      current_comments = current_model.find(:all)
    end
    return current_comments
  end
  
  def current_comments_visible
    current_comments_visible = []
    current_comments.each do |comment|
      comment.visible? ? current_comments_visible << comment : nil
    end 
    return current_comments_visible
  end
  
  def current_objects
    @current_objects ||= current_user.is_moderator? ? current_comments : current_comments_visible

    if params[:page_to_comment_id]
      @current_objects.paginate(:page => params[:page], :per_page => Comment.per_page, 
                                :conditions => ['id = ?', "#{params[:page_to_comment_id]}"])
    else
      @current_objects.paginate(:page => params[:page], :per_page => Comment.per_page) 
    end
  end

end
