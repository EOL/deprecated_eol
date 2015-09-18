!function(e,t){e.rails!==t&&e.error("jquery-ujs has already been loaded!");var i,n=e(document);e.rails=i={linkClickSelector:"a[data-confirm], a[data-method], a[data-remote], a[data-disable-with], a[data-disable]",buttonClickSelector:"button[data-remote]:not(form button), button[data-confirm]:not(form button)",inputChangeSelector:"select[data-remote], input[data-remote], textarea[data-remote]",formSubmitSelector:"form",formInputClickSelector:"form input[type=submit], form input[type=image], form button[type=submit], form button:not([type]), input[type=submit][form], input[type=image][form], button[type=submit][form], button[form]:not([type])",disableSelector:"input[data-disable-with]:enabled, button[data-disable-with]:enabled, textarea[data-disable-with]:enabled, input[data-disable]:enabled, button[data-disable]:enabled, textarea[data-disable]:enabled",enableSelector:"input[data-disable-with]:disabled, button[data-disable-with]:disabled, textarea[data-disable-with]:disabled, input[data-disable]:disabled, button[data-disable]:disabled, textarea[data-disable]:disabled",requiredInputSelector:"input[name][required]:not([disabled]),textarea[name][required]:not([disabled])",fileInputSelector:"input[type=file]",linkDisableSelector:"a[data-disable-with], a[data-disable]",buttonDisableSelector:"button[data-remote][data-disable-with], button[data-remote][data-disable]",csrfToken:function(){return e("meta[name=csrf-token]").attr("content")},csrfParam:function(){return e("meta[name=csrf-param]").attr("content")},CSRFProtection:function(e){var t=i.csrfToken();t&&e.setRequestHeader("X-CSRF-Token",t)},refreshCSRFTokens:function(){e('form input[name="'+i.csrfParam()+'"]').val(i.csrfToken())},fire:function(t,i,n){var s=e.Event(i);return t.trigger(s,n),s.result!==!1},confirm:function(e){return confirm(e)},ajax:function(t){return e.ajax(t)},href:function(e){return e.attr("href")},handleRemote:function(n){var s,o,r,a,l,c,u,h;if(i.fire(n,"ajax:before")){if(a=n.data("cross-domain"),l=a===t?null:a,c=n.data("with-credentials")||null,u=n.data("type")||e.ajaxSettings&&e.ajaxSettings.dataType,n.is("form")){s=n.attr("method"),o=n.attr("action"),r=n.serializeArray();var d=n.data("ujs:submit-button");d&&(r.push(d),n.data("ujs:submit-button",null))}else n.is(i.inputChangeSelector)?(s=n.data("method"),o=n.data("url"),r=n.serialize(),n.data("params")&&(r=r+"&"+n.data("params"))):n.is(i.buttonClickSelector)?(s=n.data("method")||"get",o=n.data("url"),r=n.serialize(),n.data("params")&&(r=r+"&"+n.data("params"))):(s=n.data("method"),o=i.href(n),r=n.data("params")||null);return h={type:s||"GET",data:r,dataType:u,beforeSend:function(e,s){return s.dataType===t&&e.setRequestHeader("accept","*/*;q=0.5, "+s.accepts.script),i.fire(n,"ajax:beforeSend",[e,s])?(n.trigger("ajax:send",e),void 0):!1},success:function(e,t,i){n.trigger("ajax:success",[e,t,i])},complete:function(e,t){n.trigger("ajax:complete",[e,t])},error:function(e,t,i){n.trigger("ajax:error",[e,t,i])},crossDomain:l},c&&(h.xhrFields={withCredentials:c}),o&&(h.url=o),i.ajax(h)}return!1},handleMethod:function(n){var s=i.href(n),o=n.data("method"),r=n.attr("target"),a=i.csrfToken(),l=i.csrfParam(),c=e('<form method="post" action="'+s+'"></form>'),u='<input name="_method" value="'+o+'" type="hidden" />';l!==t&&a!==t&&(u+='<input name="'+l+'" value="'+a+'" type="hidden" />'),r&&c.attr("target",r),c.hide().append(u).appendTo("body"),c.submit()},formElements:function(t,i){return t.is("form")?e(t[0].elements).filter(i):t.find(i)},disableFormElements:function(t){i.formElements(t,i.disableSelector).each(function(){i.disableFormElement(e(this))})},disableFormElement:function(e){var i,n;i=e.is("button")?"html":"val",n=e.data("disable-with"),e.data("ujs:enable-with",e[i]()),n!==t&&e[i](n),e.prop("disabled",!0)},enableFormElements:function(t){i.formElements(t,i.enableSelector).each(function(){i.enableFormElement(e(this))})},enableFormElement:function(e){var t=e.is("button")?"html":"val";e.data("ujs:enable-with")&&e[t](e.data("ujs:enable-with")),e.prop("disabled",!1)},allowAction:function(e){var t,n=e.data("confirm"),s=!1;return n?(i.fire(e,"confirm")&&(s=i.confirm(n),t=i.fire(e,"confirm:complete",[s])),s&&t):!0},blankInputs:function(t,i,n){var s,o,r=e(),a=i||"input,textarea",l=t.find(a);return l.each(function(){if(s=e(this),o=s.is("input[type=checkbox],input[type=radio]")?s.is(":checked"):s.val(),!o==!n){if(s.is("input[type=radio]")&&l.filter('input[type=radio]:checked[name="'+s.attr("name")+'"]').length)return!0;r=r.add(s)}}),r.length?r:!1},nonBlankInputs:function(e,t){return i.blankInputs(e,t,!0)},stopEverything:function(t){return e(t.target).trigger("ujs:everythingStopped"),t.stopImmediatePropagation(),!1},disableElement:function(e){var n=e.data("disable-with");e.data("ujs:enable-with",e.html()),n!==t&&e.html(n),e.bind("click.railsDisable",function(e){return i.stopEverything(e)})},enableElement:function(e){e.data("ujs:enable-with")!==t&&(e.html(e.data("ujs:enable-with")),e.removeData("ujs:enable-with")),e.unbind("click.railsDisable")}},i.fire(n,"rails:attachBindings")&&(e.ajaxPrefilter(function(e,t,n){e.crossDomain||i.CSRFProtection(n)}),e(window).on("pageshow.rails",function(){e(e.rails.enableSelector).each(function(){var t=e(this);t.data("ujs:enable-with")&&e.rails.enableFormElement(t)}),e(e.rails.linkDisableSelector).each(function(){var t=e(this);t.data("ujs:enable-with")&&e.rails.enableElement(t)})}),n.delegate(i.linkDisableSelector,"ajax:complete",function(){i.enableElement(e(this))}),n.delegate(i.buttonDisableSelector,"ajax:complete",function(){i.enableFormElement(e(this))}),n.delegate(i.linkClickSelector,"click.rails",function(n){var s=e(this),o=s.data("method"),r=s.data("params"),a=n.metaKey||n.ctrlKey;if(!i.allowAction(s))return i.stopEverything(n);if(!a&&s.is(i.linkDisableSelector)&&i.disableElement(s),s.data("remote")!==t){if(a&&(!o||"GET"===o)&&!r)return!0;var l=i.handleRemote(s);return l===!1?i.enableElement(s):l.fail(function(){i.enableElement(s)}),!1}return o?(i.handleMethod(s),!1):void 0}),n.delegate(i.buttonClickSelector,"click.rails",function(t){var n=e(this);if(!i.allowAction(n))return i.stopEverything(t);n.is(i.buttonDisableSelector)&&i.disableFormElement(n);var s=i.handleRemote(n);return s===!1?i.enableFormElement(n):s.fail(function(){i.enableFormElement(n)}),!1}),n.delegate(i.inputChangeSelector,"change.rails",function(t){var n=e(this);return i.allowAction(n)?(i.handleRemote(n),!1):i.stopEverything(t)}),n.delegate(i.formSubmitSelector,"submit.rails",function(n){var s,o,r=e(this),a=r.data("remote")!==t;if(!i.allowAction(r))return i.stopEverything(n);if(r.attr("novalidate")==t&&(s=i.blankInputs(r,i.requiredInputSelector),s&&i.fire(r,"ajax:aborted:required",[s])))return i.stopEverything(n);if(a){if(o=i.nonBlankInputs(r,i.fileInputSelector)){setTimeout(function(){i.disableFormElements(r)},13);var l=i.fire(r,"ajax:aborted:file",[o]);return l||setTimeout(function(){i.enableFormElements(r)},13),l}return i.handleRemote(r),!1}setTimeout(function(){i.disableFormElements(r)},13)}),n.delegate(i.formInputClickSelector,"click.rails",function(t){var n=e(this);if(!i.allowAction(n))return i.stopEverything(t);var s=n.attr("name"),o=s?{name:s,value:n.val()}:null;n.closest("form").data("ujs:submit-button",o)}),n.delegate(i.formSubmitSelector,"ajax:send.rails",function(t){this==t.target&&i.disableFormElements(e(this))}),n.delegate(i.formSubmitSelector,"ajax:complete.rails",function(t){this==t.target&&i.enableFormElements(e(this))}),e(function(){i.refreshCSRFTokens()}))}(jQuery);