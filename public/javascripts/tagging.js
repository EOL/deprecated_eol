/*
 * Any javascript stuff related to tagging
 *
 * Perhaps shouldn't be in its own file, I'm just trying to clean up
 * and really get a good feeling for all of the project's javascript!
 *
 */
EOL.Tagging = {

  // the id of the DataObject that we're currently tagging
  data_object_id: function() {
    return $$('div#public_and_private_data_object_tags input[name=tagging_data_object]')[0].value;
  },

  // the currently selected category (key)
  selected_category: function() {
    var category = $('tag[key]').value;
    if (category == '') category = 'none';
    return category;
  },

  // returns whether or not a valid category (key) is currently selected
  category_selected: function() {
    var cat = EOL.Tagging.selected_category();
    if (cat.length != 1)
      return true;
    else
      return false;
  },

  // The div that the tagging UI on the current page is wrapped in (depending on whether it's in a popup)
  wrapper_div: function() {
    return $('public_and_private_data_object_tags').parentNode;
  },

  // reload the tagging UI - pass in the ID of a new DataObject (defaults to the ID of the DataObject we're currently tagging)
  reload: function( data_object_id ) {
    if (data_object_id == null) {
      data_object_id = EOL.Tagging.data_object_id();
    }
    var path = '/data_objects/' + data_object_id + '/tags/private';
    EOL.Tagging.reload_url(path);
  },

  // reloaded the tagging UI given a specific URL
  reload_url: function( url, tag_type ) {
    new Ajax.Updater( EOL.Tagging.wrapper_div(), url, { asynchronous: true, method: 'get', onComplete: function() {EOL.Tagging.reload_tagging(tag_type);}.bind(tag_type) });
  },
  
  reload_tagging: function (tag_type) {
    EOL.reload_behaviors();
  }

};

EOL.Tagging.Behaviors = {

  // Create Tag
  '#private_data_object_tags div#add_data_object_tags div#add_data_object_tags_fields>form:submit': function(e) {
    var key   = EOL.Tagging.selected_category();
    var value = $j('#private_data_object_tags input[name="tag[value]"]')[0].value;
    var post_url = $j(this)[0].action;
    var path = post_url + '/private'
    $j.post( post_url, { 'tag[key]': key, 'tag[value]': value }, function(){ EOL.Tagging.reload() } );
    e.stop();
  },

  // Delete Tag
  '#private_data_object_tags span.data_object_tag_key_value>form:submit': function(e) {
    var post_url = $j(this)[0].action;
    var path = post_url.gsub(/tags\/.*/,'tags/private');
    $j.post( post_url, { '_method': 'delete' }, function() { EOL.Tagging.reload() } );
    e.stop();
  },

  // tagging auto-complete field
  //
  // the creator made the .autocomplete() function using jquery - we might want to port this to prototype
  // ( i looked for a prototype-based plugin, but this seemed to be the best fit for our needs )
  //
  // options:
  //
  //  mustMatch:1,          //allow only values from the list
  //  matchContains:1,      //also match inside of strings when caching
  //  selectFirst:1,        //select the first item on tab/enter
  //  removeInitialValue:0  //when first applying $.autocomplete
  //
  //  note: we've customized jquery.autocomplete specifically for this form!
  //
  'input.autocomplete': function() {
    var input = $(this);
    var path  = $j(input).attr('autocomplete_url');
    $j(input).autocomplete( path, {
      matchContains: 1,
      selectFirst: 1,
      removeInitialValue: 0
    });
  },

// Ajaxify switching between Public / Private Tags
  '#public_and_private_data_object_tags div.headers h3 a:click': function(e) {
    EOL.Tagging.reload_url(this.href, e.element().id);
    e.stop();
  },

  // Ajaxifies switching from Public -> Private Tags, given a specific link
  '#public_and_private_data_object_tags #public_data_object_tags a.tagging-link:click': function(e) {
    EOL.Tagging.reload_url(this.href);
    e.stop();
  }

};
