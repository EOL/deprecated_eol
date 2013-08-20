$(function() {

  // Collections!
  (function($collection) {
    var zi = 1000;
    // Checkboxes for selecting multiple items
    $collection.find("ul.collection_gallery").children().each(function() {
      var $li = $(this);
      if ($.browser.msie) {
        $li.css('z-index', zi);
        zi -= 1;
      }
      if (!$li.find(".checkbox input[type=checkbox]").is(':checked')) {
        $li.find(".checkbox").hide();
      }
      $li.find("h4").hide();
      $li.accessibleHover(
        function() {
          $(this).find(".checkbox").show();
          $(this).find("h4").addClass('balloon').show();
        },
        function() {
          if (!$(this).find(".checkbox input[type=checkbox]").is(':checked')) {
            $(this).find(".checkbox").hide();
          }
          $(this).find("h4").hide().removeClass('balloon');
      });
    });

    // Auto-submit if sort-by changes:
    $collection.find('#sort_by').change(function() {
      $(this).closest('form').find('input[name="commit_sort"]').click();
    });
    $collection.find('input[name="commit_sort"]').hide();
    // Auto-submit if view type (list, gallery, etc) changes:
    $collection.find('#view_as').change(function() {
      $(this).closest('form').find('input[name="commit_view_as"]').click();
    });
    $collection.find('input[name="commit_view_as"]').hide();
    $collection.find('input[name="commit_filter"]').hide();
  })($("#collection"));

  // Edit a collection item (annotation, sort field, etc) TODO - generalize this with the other modals...
  $('#collection_items .editable .edit a').modal({
    beforeSend: function() { $('#collection_items .editable a').fadeTo(225, 0.3); },
    beforeShow: function() {
      $('form.edit_collection_item :submit').click(function() {
        EOL.ajax_submit($(this), { update: $('li#collection_item_'+$(this).attr('data-id')+' div.editable') });
        $('#collection_items_edit a.close').click();
        return(false);
      });
    },
    afterClose: function() {
      $('#collection_items .editable a').delay(25).fadeTo(100, 1, function() {$('#collection_items .editable a').css({filter:''}); });
    },
    duration: 200
  });

  // When you select all items, hide the checkboxes (and vice-versa) on collection items:
  $('form.new_collection_job #scope').change(function() {
    if ($('form.new_collection_job #scope').val() == 'all_items') {
      $('#collection_items :checkbox').parent().hide();
    } else {
      $('#collection_items :checkbox').parent().show();
    }
  });

  $('input.clear_on_focus').each(function() { $(this).val($(this).attr('data-default')); });
  $('input.clear_on_focus').siblings().each(function() { $(this).on('click', function() {
    if ($(this).prop('checked')) {
      $(this).siblings().focus()
    }
  })});
  $('input.clear_on_focus').on('focus', function() {
    if ($(this).val() == $(this).attr('data-default')) {
      $(this).val('');
      EOL.check_siblings(this, true);
    }
  });
  $('input.clear_on_focus').on('blur', function() {
    if ($(this).val() == '' || $(this).val() == $(this).attr('data-default')) {
      $(this).val($(this).attr('data-default'));
      EOL.check_siblings(this, false);
    }
  });

  $('input#collection_job_overwrite').on('click', function() {
    if ($(this).prop('checked')) {
      $('form#new_collection_job li.collected input').prop('checked', false).attr("disabled", false);
    } else {
      $('form#new_collection_job li.collected input').prop('checked', true).attr("disabled", true);
    }
  });

  (function($inat_link) {
    $inat_link.attr('href', function() { 
      auth_provider = $('.inat_observations_header a.button').attr('href').split("&")[1];
      if (typeof auth_provider != "undefined") {
        return this.href + '?' + auth_provider;
      }
    });
  })($(".inat_top_contributors a"));

});
