/*
 * EOL Javascript : Common functions, Global variables, etc
 *
 * This defines the EOL namespace which can be used for various common functions that get used throughout the application.
 */
if(!EOL)var EOL={};EOL.log_enabled=!0,EOL.log=function(e){if(EOL.log_enabled)try{console.log(e)}catch(t){EOL.log_enabled=!1}},EOL.close_open_overlays=function(){$(".overlay a.close").click()},jQuery.ajaxSetup({beforeSend:function(e){e.setRequestHeader("Accept","text/javascript")}});