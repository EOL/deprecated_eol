$(document).ready(function(){$("#select_all").click(function(){this.checked?$(":checkbox").each(function(){this.checked=!0}):$(":checkbox").each(function(){this.checked=!1})})});

$(function() {
  $('table.taxon_collection tr .info_icon, table.taxon_collection.search tr .info_icon').each(function() {
    EOL.create_collection_taxon_info_dialog(this);
  });
});
