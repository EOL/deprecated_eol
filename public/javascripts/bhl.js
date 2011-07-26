//
//     /pages/:taxon_concept_id/literature/bhl
//

$(function() {
  $('#sort_by').change(function() {
    $(this).closest('form').find('input[name="sort_by"]').click();
  });
  $('#sort_by').closest('form').find('input[type="submit"]').hide();
});
