  function changeList(){
      if ($('#sort_collection_by').val() == 'alpha') {
        $('#collections_alpha').show();
        $('#collections_recent').hide();
      } else if ($('#sort_collection_by').val() == 'recent') {
        $('#collections_alpha').hide();
        $('#collections_recent').show();
      }
    };