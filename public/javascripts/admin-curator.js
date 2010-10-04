$(document).ready(function() {
  // Heavy-duty removal of a user that wanted to be a curator.
  $('div#users a.remove_link').click(function() {
    var notes = prompt ("Are you sure you want to remove this user from the curator list?  If so, enter a reason below.  They will be removed immediately, their clade, credentials and scope will be cleared immediately, and they will not be notified.","");
    if (notes != null) {
      $.ajax({
        url: $(this).attr('href'),
        data:{notes:escape(notes)}
      });
    }
    $(this).hide();
    $(this).parent().parent().fadeOut(1000);
    $(this).parent().html("removed");
    return false;
  });
  // TODO - The id on every one of these elements is the same.  Probably not good.  This is a weak selector, as-is:
  $('td input[id]').change(function() {
    form = $(this).parent('form')
    $.ajax({data:$(form).serialize(), type:'POST', url:$(form).attr('action')})
  });
});
