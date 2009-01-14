# TODO - PRI LOW - none of the actions actually do any finding here, the views all use 
#                  data_object directly (because it has some nice tag-related helper methods)
#
class TagsController < ApplicationController
  
  layout proc { |c| c.request.xhr? ? false : "main" }

  before_filter :set_data_object

  # GET /data_objects/1/tags
  def index
    public # redirect_to :action => 'public' # ... call public, without actually redirecting ... redirect makes ajax mad
  end
  
  #TODO : Clean this up a bit, I've combined views so that there is only ever a need for one tagging window and it will show both private and public
  #   tags, but the views and methods still act like there are two views
  
  # GET /data_objects/1/tags/public
  def public
    @public_tags = @data_object.public_tags 
    @private_tags = current_user.tags_for @data_object if logged_in?    
    render :template => 'tags/public_or_private'
  end

  # GET /data_objects/1/tags/private
  def private
    @public_tags = @data_object.public_tags     
    @private_tags = current_user.tags_for @data_object if logged_in?
    render :template => 'tags/public_or_private'
  end

  # POST /data_objects/1/tags
  #
  # gross parsing and whatnot here - method needs clean-up
  #
  def create
    if logged_in? and params.include?:tag and params[:tag].include?:value

      # allow multiple values, eg: 'red, blue' or 'red blue' (TODO - pri low - move this logic into a model)
      value = params[:tag][:value]
      key = params[:tag][:key] 
      key = (key.blank? ? 'none' : key)
      if value.include?','
        values = value.split ','
      elsif value.include?' '
        values = value.split ' '
      else
        values = [value]
      end

      # strip out any spaces / newlines in values (model handles punctuation, etc, if found)
      values.map! {|v| v.gsub("\n",'').gsub(' ','') }

      if @data_object.tag key, values, current_user
        flash[:notice] = 'New tag was successfully created'
      else
        # 
      end
    end
    redirect_to request.referer ? :back : data_object_tags_path(@data_object.id)
  end

  # GET /data_objects/1/tags/color ????
  # GET /data_objects/1/tags/color:red
  # GET /data_objects/1/tags/color=red
  #
  # we don't really use this show page, but we need to have a show
  # page if we're going to have a destroy action ... we need 
  # a url to send our DELETE to  :P
  def show
    # really, there is no 'show' page for a Tag.  the show page is really a list of all objects tagged with that tag, ie. *search*
    redirect_to :action => 'search', :q => params[:id]
  end

  # DELETE /data_objects/1/tags/color ????
  # DELETE /data_objects/1/tags/color:red
  #
  # using the same logic as show
  def destroy
    key, value = params[:id].split(':')
    @tag = DataObjectTag[key, value] if key and value
    unless @tag
      render :text => "Tag not found: #{ params[:id] }"
    else

      @tags = DataObjectTags.find_all_by_data_object_id_and_data_object_tag_id(@data_object.id, @tag.id)

      #if @data_object.has_tag?@tag
      if @tags
        # render :text => "DataObject is tagged with #{ params[:id] }"
        @my_tag = @tags.find {|t| current_user &&  t.user_id == current_user.id }
        if @my_tag
          @my_tag.destroy
          flash[:notice] = "Successfully removed tag #{ params[:id] }"
          redirect_to request.referer ? :back : data_object_tags_path(@data_object.id)
        else
          render :text => "DataObject is tagged with #{ params[:id] } but not by you, so you cannot delete this tag."
        end
      else
        render :text => "DataObject #{ @data_object.id } doesn't have tag: #{ params[:id] }"
      end
    end
  end

  # POST /data_objects/1/tags/add_category
  #
  # POST clear => 'anything' to clear this
  # POST new_tag_key => 'foo' to add a category
  #
  # used to temporarily add a new key (aka 'category') to the drop down (hold it in the session)
  def add_category
    if params[:clear]
      session[:user_added_data_object_tag_keys] = []
    end
    if params[:new_tag_key] and not params[:new_tag_key].empty?
      session[:user_added_data_object_tag_keys] ||= []
      session[:user_added_data_object_tag_keys] << params[:new_tag_key].gsub(/[\s]+/,'_')
    end
    redirect_to request.referer ? :back : data_object_tags_path(@data_object.id)
  end

  # GET /data_objects/1/tags/autocomplete_for_tag_key?q=partial-key
  #
  # We really want to suggest all (public) keys, ever.  So this is not restricted like values.
  def autocomplete_for_tag_key
    values      = params[:q].split(' ')
    last_value  = values.pop
    suggestions = DataObjectTag.suggest_key(last_value)

    if suggestions.empty?
      render :nothing=>true
    else
      if suggestions.first == last_value and params[:q].ends_with?' ' # we typed a space and wanna see possibilities
        # get ALL values for this key and show them (after the current values, eg. blue red [some-value]')
        suggestions = DataObjectTag[tag_key].map(&:value) if suggestions.first == last_value and params[:q].ends_with?' '
        suggestions.reject! {|s| values.include?(s) or last_value == s }
        render :text => suggestions.map {|s| "#{values.join(' ')} #{last_value} #{s}".strip }.join("\n")
      else
        render :text => suggestions.map {|s| "#{values.join(' ')} #{s}".strip }.join("\n")
      end
    end
  end
  
  # GET /data_objects/1/tags/color/autocomplete_for_tag_value?q=partial-tag
  #
  # add the # of uses to the string?
  def autocomplete_for_tag_value

    tag_key     = params[:id]
    tags        = current_user.tags_for @data_object # grab this user's tags for this object
    tagged_with = tags.select {|t| t.key == tag_key }.map {|t| t.value }
    values      = params[:q].split(' ')
    last_value  = values.pop
    suggestions = DataObjectTag.suggest_value(last_value, tag_key) - tagged_with

    unless suggestions.empty?
      if suggestions.first == last_value and params[:q].ends_with?' ' # we typed a space and wanna see possibilities
        # get ALL values for this key and show them (after the current values, eg. blue red [some-value]')
        suggestions = DataObjectTag[tag_key].map(&:value) if suggestions.first == last_value and params[:q].ends_with?' '
        suggestions.reject! {|s| values.include?(s) or last_value == s }
        suggestions = suggestions - tagged_with
        render :text => suggestions.map {|s| "#{values.join(' ')} #{last_value} #{s}".strip }.join("\n")
      else
        render :text => suggestions.map {|s| "#{values.join(' ')} #{s}".strip }.join("\n")
      end
    else
      render :nothing=>true #:text => params[:q] # send back what we got
    end
    #render :text => DataObjectTag.suggest_value( params[:q], params[:id] ).join("\n")
  end

  # GET /tags/cloud
  # GET /data_objects/1/tags/cloud
  #
  # TODO - i disabled this action - it's no longer enabled in the routes.  needs a nice view.  remove this entirely if we won't use this
  #
  def cloud
    if @data_object
      @tags_with_count = DataObjectTags.tags_with_usage_count.find_all_by_data_object_id @data_object.id
    else
      @tags_with_count = DataObjectTags.tags_with_usage_count
    end
    # sort by the tag name and inject into an array like: [ [7,<tag>], [5,<tag>], ... ]
    @tags_with_count = @tags_with_count.sort_by {|t| t.tag.to_s }.inject([]){|all,this| all << [this.usage_count.to_i, this.tag]; all }
  end

  # AHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  #   GROSS.
  #     cleaning this up via spec/models/data_object_tag_search_spec.rb ...
  #
  # GET /tags/search?q=color:blue,habitat:marsh
  def search
    
    # REDIRECT TO COMBINED SEARCH PAGE
    redirect_to :controller=>'taxa',:action=>'search',:q=>params[:q],:search_type=>'tag'
    return
    
    # TODO: Remove deprecated tag search code below
    if params[:q]
      tags = params[:q].split(',').map &:strip
      @tags = tags.inject([]) do |all,this|
        if this.include?':'
          key, value = this.split(':')
        else
          key, value = this.split('=')
        end
        if key && value
          all << DataObjectTag[key, value]
        elsif key
          RAILS_DEFAULT_LOGGER.warn { "all += #{key}:#{ DataObjectTag[key].inspect }" }
          all += DataObjectTag[key] # get all tags that use the given key
        end
        all
      end
      @tags = @tags.compact.uniq
      RAILS_DEFAULT_LOGGER.warn { @tags.map(&:to_s).inspect }

      options = (params['selected-clade-id'] and params['selected-clade-id'].to_i > 0) ? { :clade => params['selected-clade-id'].to_i } : {}
      @data_objects = DataObject.search_by_tags @tags, options
    else
      @data_objects = []
    end
  end

  protected

  def set_data_object
    @data_object = DataObject.find params[:data_object_id].to_i if params[:data_object_id]
  end

end
