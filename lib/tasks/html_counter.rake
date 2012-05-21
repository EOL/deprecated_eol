def build_field_hashes_after_env_load
  # I doubt we care about these.  Unused at the moment.
  sanitized = {
    Resource => [:title],
    TaxonConcept => [:title_canonical],
    ContentPage => [:main_content],
    DataObject => [:description],
    Ref => [:full_reference]
  }

  # I don't think we care about these right now.  Unused at the moment.
  admin_input = {
    Comment => [:body],
    ContactSubject => [:title, :recipients],
    ContentPartner => [:name],
    ContentPage => [:page_name], # Missing body?
    # Global site warning, not worth checking.
    GlossaryTerm => [:definition, :term],
    Hierarchy => [:description, :label, :descriptive_label],
    NewsItem => [:translated_title],
    SearchSuggestion => [:notes, :term, :content_notes],
    TranslatedContentPage => [:title, :meta_keywords, :meta_description], # Missing body?
    User => [:curator_scope, :credentials, :notes, :username, :email, :given_name, :family_name]
  }

  user_input = {
    CollectionItem => [:annotation, :sort_field],
    Collection => [:description, :name],
    Comment => [:body],
    Community => [:description, :name],
    Contact => [:comments, :name, :email],  # Not used anymore?
    ContentPartner => [:description, :description_of_data, :notes, :admin_notes, :full_name, :acronym, :display_name, :homepage],
    ContentPartnerAgreement => [:body, :mou_url, :signed_by],
    ContentPartnerContact => [:address, :given_name, :family_name, :email, :homepage, :telephone],
    DataObject => [:description, :bibliographic_citation, :object_title, :rights_holder, :rights_statement, :source_url],
    Hierarchy => [:description, :label, :descriptive_label],
    Name => [:string], # Only if added by a user.
    Ref => [:full_reference],
    Resource => [:bibliographic_citation, :description, :title, :accesspoint_url, :rights_holder, :rights_statement],
    User => [:curator_scope, :credentials, :bio, :given_name, :family_name, :tag_line, :username, :email]
    # Wikipedia thingie :revision_url ...no on will ever see that.
  }

  # TODO - decide if we want to merge hashes at all:
  user_input
end

def count_html_tags(string, opened, closed)
  return if string.nil?
  s = string.dup

  close_re = /<\s*\/\s*(\w+)[^>]*>/
  while(s =~ close_re) do
    tag = $1
    closed[tag] ||= 0
    closed[tag] += 1
    s.sub!(close_re, '')
  end

  open_re = /<\s*(\w+)[^>]*>/
  while(s =~ open_re) do
    tag = $1
    opened[tag] ||= 0
    opened[tag] += 1
    s.sub!(open_re, '')
  end
end

def report_on_tags(opened, closed)
  puts "\n** Complete."
  puts "\nOpen tags:"
  puts " ...none found, something must have failed" if opened.keys.empty?
  opened.keys.sort.each do |k|
    print "  #{k}:#{opened[k]}"
    if closed.has_key?(k)
      if closed[k] < opened[k]
        puts " (#{opened[k] - closed[k]} unclosed)"
      else
        print "\n"
      end
    else
      puts " (NONE closed)"
    end
  end
end

desc 'Count the HTML tags in a field in the DB'
task :html_counter => :environment do
  field_hash = build_field_hashes_after_env_load
  opened = {}
  closed = {}
  begin
    field_hash.keys.each do |klass|
      print "\nCounting #{klass.name.pluralize}"
      counter = 0
      # TODO - if klass == Name, then don't use :all, just find user-submitted names.
      # TODO - if klass == DataObject, then don't use :all, just find user-submitted text.
      klass.send(:all, :select => field_hash[klass].map {|sy| sy.to_s}.join(', ')).each do |instance|
        if counter % 100 == 0 
          print "."
        end
        field_hash[klass].each do |field|
          count_html_tags(instance.send(field), opened, closed)
        end
        counter += 1
      end
    end
  ensure
    print "\n"
    report_on_tags(opened, closed)
  end
end
