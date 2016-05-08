// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery-2.1.3
//= require jquery-migrate-1.2.1
//= require jquery_ujs
//= require jquery-ui-1.10.3.custom.min
//= require autocomplete-rails
//= require common
//= require taxon_data
//= require jquery.cycle.all.min
//= require jquery.modal
//= require comments
//= require navigation
//= require combobox
//= require angular
//= require react
//= require react_ujs
//= require components


$(document).ajaxSend(function(e, xhr, options) {
  var token = $("meta[name='csrf-token']").attr("content");
  xhr.setRequestHeader("X-CSRF-Token", token);
});
