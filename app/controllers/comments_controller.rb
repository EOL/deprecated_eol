class CommentsController < ApplicationController
  layout 'main'

  helper :taxa

  make_resourceful do
    actions :all, :except => :edit
    belongs_to :data_object, :taxon_concept

    before :index do
      raise "Comments are only meaningful when associated with an object" unless parent?
      prepare_index
    end

    before :create do
      current_object.user_id = current_user.id
    end

    after :create do
      current_object.save
      current_user.log_activity(:posted_comment_id, :value => current_object.id)
    end

    response_for :create do |format|
      format.js do
        replace_div = params[:body_div_name].blank? ? 'commentsContain' : params[:body_div_name]
        begin
          params[:page] = (parent_object.visible_comments(current_user).length.to_f / Comment.per_page.to_f).ceil
          params[:page] = 1 if params[:page] <= 0
          prepare_index
          render :update do |page|
            page.replace_html replace_div,
              # Weird, but text comments has a different way of loading its contents.  TODO - normalize this.
              {:partial => replace_div.start_with?('text') ? 'index.js' : 'index_contents.js',
               :locals => {:body_div_name => replace_div},
               :object => [parent_object, current_object] }
          end
        rescue => e
          render :update do |page|
            page.replace_html replace_div,
              {:partial => 'error.js.haml',
               :locals => {:message => e.message},
               :object => [parent_object, current_object] }
          end
        end
      end
    end

    response_for :index do |format|
      format.js {
        render :partial => (params[:page].blank? || params[:body_div_name].start_with?('text')) ? 'index.js' : 'index_contents.js',
               :locals => {
                 :add_wrapper => !params[:tab].blank?,
                 :body_div_name => params[:body_div_name].blank? ? 'commentsContain' : params[:body_div_name]
               }
      }
    end

  end

  def prepare_index
    @comment = Comment.new(:user => current_user)
    @parent = parent_object
    @type   = :image if @comment.image_comment?
    @type   = :text  if @comment.text_comment?
    @type   = :taxon if @comment.taxa_comment?
    @slim_container = true # So, this will re-arrange some of the view, based on which format we have to play with.
    if @type == :image
      @title_label    = 'above image'
      @title = '' # @parent.description.blank? ? 'Above Image' : @parent.description
      @current_params = "data_object_id=#{params[:data_object_id]}"
      current_user.log_activity(:viewed_comments_on_image_id, :value => params[:data_object_id])
    elsif @type == :text
      @title          = '' # "#{@parent.authors.collect {|a| a.full_name}.join(',<br />')}"
      @title_label    = 'above text'
      #@title_label   += ' by' unless @title.empty?
      @current_params = "data_object_id=#{params[:data_object_id]}"
      current_user.log_activity(:viewed_comments_on_text_id, :value => params[:data_object_id])
    elsif @type == :taxon
      @title          = @parent.title
      @slim_container = false
      current_user.log_activity(:viewed_comments_on_taxon_concept_id, :taxon_concept_id => @parent.id)
    end
  end

  #show/hide comment
  def remove
    current_user.log_activity(:removed_comment_id, :value => current_object.id)
    current_user.unvet current_object
    render :partial => 'remove'
  end

  def make_visible
    current_user.log_activity(:make_visible_comment_id, :value => current_object.id)
    current_user.vet current_object
    render :partial => 'make_visible'
  end

private

  def current_comments
    comments = []
    if parent_name == 'data_object'
      comments = parent_object.all_comments
    else # "taxon_concept"
      t = TaxonConcept.find(parent_object.id, :include => [ :comments, {:superceded_taxon_concepts => :comments} ],
        :select => "taxon_concepts.id, taxon_concepts.supercedure_id, comments.*")

      previous_comments = t.superceded_taxon_concepts.collect do |tc|
        tc.comments
      end.flatten.compact

      comments = t.comments + previous_comments
    end
    comments
  end

  def current_comments_visible
    current_comments.select {|c| c.visible? }
  end

  def current_objects
    @current_objects ||= current_user.is_moderator? ? current_comments : current_comments_visible
    if params[:page_to_comment_id]
      @current_objects.dup.paginate(:page => params[:page], :per_page => Comment.per_page,
                                :conditions => ['id = ?', "#{params[:page_to_comment_id]}"])
    else
      @current_objects.dup.paginate(:page => params[:page], :per_page => Comment.per_page)
    end
  end

end
