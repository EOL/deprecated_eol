function intialize_attribute_list(){".custom-combobox-input".val(""),$(".custom-combobox-input").attr("placeholder","translation missing: en.helpers.label.data_search.attribute")}$(document).ready(function(){$("#taxon_name_id, #autocomplete_q").bind("change",function(){$.ajax({url:"/data_search/update_attributes",dataType:"script"})}),intialize_attribute_list()}),function(t){"function"!=typeof String.prototype.trim&&(String.prototype.trim=function(){return this.replace(/^\s+|\s+$/g,"")}),t.fn.fadeInline=function(e){var i={duration:200,display:"inline-block"},n=t.extend(i,e);return this.each(function(){t(this).css({opacity:0,display:n.display}).fadeTo(n.duration,1)})},t.fn.summarizeInput=function(e){var i={truncate:0,panel:t(this),container:t("<p/>",{"class":"summarize_input"}),wrapper:t("<span/>"),exclude:{}},n=t.extend(i,e);return this.each(function(){var e=t(this).find("label"),i=t(this).find(":input"),s=[];if(output="",i.each(function(){var i=this.name,o=t.grep(e,function(e){return t(e).attr("for")==i})[0],a="select-one"==this.type?t(this.selectedOptions).text():this.value,r="undefined"!=typeof n.exclude[i]&&(0===n.exclude[i].length||0===t.inArray(this.value,n.exclude[i]));a&&!r&&s.push([t(o).text(),n.truncate>0&&a.length>n.truncate?a.substr(0,n.truncate)+"…":a])}),s.length>0){for(var o in s)s[o]=s[o].join(": ");n.wrapper.text(s.join("; ")).appendTo(n.container),n.container.hide().appendTo(n.panel).fadeIn(500)}})},t(function(){!function(e){function i(){for(var t in o)o[t].is(":disabled")?o[t].attr("placeholder")!=r[t]&&o[t].attr("placeholder",r[t]):o[t].attr("placeholder")!=o[t].data("placeholder")&&o[t].attr("placeholder",o[t].data("placeholder"))}function n(t){t.stopImmediatePropagation(),o.min.prop("disabled",o.q.val().trim()),o.max.prop("disabled",o.q.val().trim()),a.prop("disabled",o.q.val().trim()),o.q.prop("disabled",o.min.val().trim()||o.max.val().trim()),o.min.is(":disabled")&&o.max.is(":disabled")&&o.q.is(":disabled")&&o.q(":disabled",!1),i()}var s=e.find(".vital"),o={q:e.find('input[name="q"]'),min:e.find('input[name="min"]'),max:e.find('input[name="max"]')},a=e.find('select[name="unit"]'),r={q:o.q.data("disabled-placeholder"),min:o.min.data("disabled-placeholder"),max:o.max.data("disabled-placeholder")},l=e.find('input[name="taxon_name"]'),c={taxonName:l.data("value-removed-placeholder")};t("<fieldset/>",{"class":"prominent_actions",html:t("<legend/>",{"class":"assistive",text:"Additional search submit"})}).append(e.find('#traitbank_search input[type="submit"]').clone().attr("title","Search now or move on to add more search criteria")).appendTo(s),"string"==typeof c.taxonName&&c.taxonName.length>0&&(l.data("placeholder",l.attr("placeholder")),l.attr("placeholder",c.taxonName),l.one("keyup input paste",function(){l.attr("placeholder",l.data("placeholder"))}));for(var h in o)o[h].data("placeholder",o[h].attr("placeholder")),o[h].on("keyup input paste",{n:h},n),o[h].keyup();if(e.data("results-total")>0){var u=e.find(".extras"),d=e.find("fieldset.actions"),p=t("<a/>",{href:"#"}),f={truncate:50,panel:s,container:t("<dl/>",{"class":"summarize_input"}).append(t("<dt/>").append(u.data("summary-intro"))),wrapper:t("<dd/>"),exclude:{sort:[]}};p.hide().appendTo(s),adjustSummarizeExclude=function(){o.min.val().trim()||o.max.val().trim()?"undefined"!=typeof f.exclude.unit&&delete f.exclude.unit:f.exclude.unit=[]},hide=function(){d.fadeOut(200),adjustSummarizeExclude(),u.slideUp(500,function(){p.fadeOut(200,function(){t(this).text(u.data("show")).fadeInline()})}).summarizeInput(f)},show=function(){u.slideDown(500,function(){p.fadeOut(200,function(){t(this).text(u.data("hide")).fadeInline()}),f.container.fadeOut(500,function(){f.wrapper.remove(),t(this).detach()})}),d.fadeIn(500)},t.each([p,f.container.find("a")],function(t,e){e.accessibleClick(function(){return u.is(":visible")?hide():show(),!1})}),hide()}}(t("#data_search")),limit_search_summaries()})}(jQuery);var limit_search_summaries=function(){var t=$(".search_summary:has(ul.values)");if(t.find("li").length>9){t.find("li:gt(8)").slideUp(500);var e=t.find("li").length-9,i="Show "+e+" more",n=$('<a href="#">').text(i);n.on("click",function(e){e.preventDefault(),"true"===$(this).attr("data-open")?t.find("li:gt(8)").slideUp(500,function(){n.text(i),n.attr("data-open","false")}):t.find("li:gt(8)").slideDown(500,function(){n.text("Hide"),n.attr("data-open","true")})}),t.append($('<span class="more"></span>').append(n))}};