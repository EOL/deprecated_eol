EOL.prep_flashes();

$(function() {
  $('.data input').change(function() {
    EOL.ajax_submit($(this), {url: $(this).data('href')+'&value='+$(this).is(':checked'), update: $('#flashes'), type: 'GET'});
  });
});
