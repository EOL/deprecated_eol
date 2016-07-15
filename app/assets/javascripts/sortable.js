$(function() {
  $('#sortable.standard.uris').sortable({
    placeholder: "placeholder", items: "tr:not(.headers)", helper: 'clone', tolerance: 'pointer',
    update: function(e, ui) {
      $.post("/known_uris/sort", { known_uris: $("#sortable").sortable('toArray'), moved_id: ui.item.attr('id') });
    }
  }).disableSelection();

  $('#sortable a.to_top').on('click', function() {
    $.post("/known_uris/sort", { to: 'top', moved_id: $(this).closest('tr').attr('id') });
    return(false);
  });

  $('#sortable a.to_bottom').on('click', function() {
    $.post("/known_uris/sort", { to: 'bottom', moved_id: $(this).closest('tr').attr('id') });
    return(false);
  });

  $('#sortable a.to_top_p_harvest').on('click', function() {
    $.post("/pending_harvests/sort", { to: 'top', moved_id: $(this).closest('tr').attr('id') });
    return(false);
  });

  $('#sortable a.to_bottom_p_harvest').on('click', function() {
    $.post("/pending_harvests/sort", { to: 'bottom', moved_id: $(this).closest('tr').attr('id') });
    return(false);
  });

  $('#sortable.standard.pending_harvests').sortable({
    placeholder: "placeholder", items: "tr:not(.headers)", helper: 'clone', tolerance: 'pointer',
    update: function(e, ui) {
      $.post("/pending_harvests/sort", { pending_harvests: $("#sortable").sortable('toArray'), moved_id: ui.item.attr('id') });
    }
  }).disableSelection();

  $('#pause_p_harvest').on('click', function() {
    document.getElementById("pause_pending_harvests").style.display = "none";
    document.getElementById("resume_pending_harvests").style.display = "block";
    $.post("/pending_harvests/pause_harvesting");
    return(false);
  });

  $('#resume_p_harvest').on('click', function() {
    document.getElementById("resume_pending_harvests").style.display = "none";
    document.getElementById("pause_pending_harvests").style.display = "block";
    $.post("/pending_harvests/resume_harvesting");
    return(false);
  });
});
