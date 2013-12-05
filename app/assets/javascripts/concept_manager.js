dragged_div = null;
$(document).ready(function() {
  $("#tc1 + input").on('click', function() { lookup_concept('#tc1');});
  $("#he1 + input").on('click', function() { lookup_entry('#he1');});
  $("#tc2 + input").on('click', function() { lookup_concept('#tc2');});
  $("#he2 + input").on('click', function() { lookup_entry('#he2');});
  
  $("#merge_concepts")
    .hover(
      function() {
        $(this).addClass('entry_hover');
      }, 
      function() {
        $(this).removeClass('entry_hover');
      }
    )
    .on('click', function() {
      var num_left_entries = $("#left_panel .entry_details").length;
      var num_right_entries = $("#right_panel .entry_details").length;
      if(num_left_entries == 0 || num_right_entries == 0) {
        alert('You can only merge two concepts');
        return;
      }
      
      var taxon_concept_id1 = $("#left_panel .entry_details:first").attr('taxon_concept_id');
      var taxon_concept_id2 = $("#right_panel .entry_details:first").attr('taxon_concept_id');
      if(taxon_concept_id1 == taxon_concept_id2) {
        alert('Cannot merge: these concepts are the same');
        return;
      }
      
      supercede_concepts(taxon_concept_id1, taxon_concept_id2);
    });
  
  
  $("#split_concepts")
    .hover(
      function() {
        $(this).addClass('entry_hover');
      }, 
      function() {
        $(this).removeClass('entry_hover');
      }
    )
    .mouseup(function(event, ui) {
      if(typeof dragged_div == "undefined") { alert('fail1'); return; }
      if(dragged_div == null) { alert('fail2'); return; }
      
      previously_dragged_div = dragged_div;
      dragged_div.css('z-index', 10);
      dragged_div = null;
      
      dropped_div = $(".entry_hover");
      if(typeof dropped_div == "undefined") { alert('fail'); return; }
      
      //alert(previously_dragged_div.attr('hierarchy_entry_id'));
      split_entry(previously_dragged_div.attr('hierarchy_entry_id'));
    });
});


function lookup_concept(input_id) {
  lookup_id(input_id, '/concept_manager/lookup_concept/');
}
function lookup_entry(input_id) {
  lookup_id(input_id, '/concept_manager/lookup_entry/');
}

function lookup_id(input_id, url_prefix) {
  var input = $(input_id);
  $.ajax({
    url: url_prefix + input.val(),
    beforeSend: function(xtr) { input.siblings(".entries").html('<p style="text-align: center;"><img src="/assets/green_loader.gif"/></p>'); },
    success: function(response) {
      input.siblings(".entries").html(response);
      input.siblings(".entries").attr('taxon_concept_id', $(this).attr('id'));
      add_drag_events_to_selector(input);
    },
    error: function(xtr) { input.siblings(".entries").html('lookup failed'); }
  });
}

function supercede_concepts(id1, id2) {
  $.ajax({
    url: '/concept_manager/supercede_concepts?id1=' + id1 + '&id2=' + id2,
    beforeSend: function(xtr) {
      $("#left_panel .entries, #right_panel .entries").html('<p style="text-align: center;"><img src="/assets/green_loader.gif"/></p>');
    },
    success: function(response) {
      $("#right_panel .entries").html('');
      var lookup_id = id1;
      if(id2 < id1) { lookup_id = id2; }
      $("#tc1").val(lookup_id);
      lookup_concept('#tc1');
      alert('Concepts were successfully merged');
    },
    error: function(xtr) {
      $("#right_panel .entries").html('');
      $("#left_panel .entries").html('something went wrong');
    }
  });
}

function split_entry(id) {
  $.ajax({
    url: '/concept_manager/split_entry_from_concept/' + id,
    beforeSend: function(xtr) {
      $("#left_panel .entries, #right_panel .entries").html('<p style="text-align: center;"><img src="/assets/green_loader.gif"/></p>');
    },
    success: function(response) {
      $("#right_panel .entries").html('');
      var lookup_id = response;
      $("#tc1").val(lookup_id);
      lookup_concept('#tc1');
      alert('Concepts were successfully merged');
    },
    error: function(xtr) {
      $("#right_panel .entries").html('');
      $("#left_panel .entries").html('something went wrong');
    }
  });
}


function add_drag_events_to_selector(input) {
  input.siblings(".entries").children(".entry_details")
    .hover(
      function() {
        $(this).addClass('entry_hover');
      }, 
      function() {
        $(this).removeClass('entry_hover');
      }
    )
    .draggable({
      opacity: 0.50,
      revert: true,
      start: function(event, ui) {
        dragged_div = $(this);
        $(this).css('z-index', 9);
      }
    })
    .mouseup(function(event, ui) {
      if(typeof dragged_div == "undefined") { return; }
      if(dragged_div == null) { return; }
      
      previously_dragged_div = dragged_div;
      dragged_div.css('z-index', 10);
      dragged_div = null;
      
      dropped_div = $(".entry_hover");
      if(typeof dropped_div == "undefined") { alert('fail'); return; }
      
      // same concept
      if(dropped_div.attr('hierarchy_entry_id') == previously_dragged_div.attr('hierarchy_entry_id')) {
        alert('Cannot drop - same concept');
      }
      else if(dropped_div.attr('taxon_concept_id') == previously_dragged_div.attr('taxon_concept_id')) {
        alert('Cannot drop - same concept');
      } else {
        alert('Dropping '+ previously_dragged_div.attr('hierarchy_entry_id') + ' to ' + dropped_div.attr('hierarchy_entry_id'));
      }
    });
}
