/*

jQuery Spotlite Plugin
version 0.1.4

Copyright (c) 2011 Cameron Daigle, http://camerondaigle.com

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

;(function($) {

  $.fn.spotlite = function(options, secondary) {
    return this.each(function() {

      var $spot = $(this),
          spot = {};

      if (typeof options === 'string') {
        switch (options) {
          case 'refresh':
            init($spot, secondary);
            break;
        }
      } else {
        spot = init($spot, options);
        attachEvents(spot);
      }

    });
  };

  function init($spot, options) {

    var defaults = {
      pool: '',
      result_list: $spot.find("ul").first(),
      input_field: $spot.find("input[type='text']"),
      result_limit: 10,
      threshold: 1,
      exclude_characters: '\\W',
      bypass: '',
      multiselect: true,
      class_prefix: 'spotlite',
      output: function(e) { return $("<li />").html(e); }
    };

    var temp_settings = {
      cache: [],
      current_val: '',
      match_count: 0
    };

    var spot = {};

    if ($spot.data('opts.spotlite')) {
      spot = $.extend($spot.data('opts.spotlite'), options, temp_settings);
    } else {
      spot = $.extend(defaults, options, temp_settings);
    }

    if (spot.bypass.length) {
      spot.bypass = spot.bypass.replace(" ", "").split(",");
    }

    spot.input_field.addClass(spot.class_prefix + "-input");

    if (!options.match_list) {
      spot.match_list = $("body > ul." + spot.class_prefix + "-matches").hide();
      if (!spot.match_list.length) {
        spot.match_list = $("<ul />").addClass(spot.class_prefix + "-matches").appendTo($("body")).hide();
      }
    }

    if (!options.result_list && spot.multiselect && !$spot.find("." + spot.class_prefix + "-results").length) {
      spot.result_list = $("<ul />").addClass(spot.class_prefix + "-results").insertAfter(spot.input_field);
    }

    spot.sanitize = function(str) {
      return str.replace(new RegExp(spot.exclude_characters, 'gi'), ' ');
    };

    spot.showMatches = function() {
      var $input = spot.input_field;
      var border_width = parseInt(spot.match_list.css('border-left-width').replace('px', ''), 10);
      border_width += parseInt(spot.match_list.css('border-right-width').replace('px', ''), 10);
      spot.match_list.css({
        position: 'absolute',
        'z-index': 1000,
        left: $input.offset().left + 'px',
        top: $input.offset().top + parseInt($("body").css("border-top-width").replace("px", ""), 10) + $input.outerHeight() + 'px',
        width: $input.outerWidth() - border_width
      }).show();
      return spot.match_list;
    };

    if (typeof spot.pool === 'string') {
      $.getJSON(spot.pool, function(data) {
        generatePool.call(spot, data);
      });
    } else {
      generatePool.call(spot);
    }
    $spot.data('opts.spotlite', spot);

    return spot;

  }

  function attachEvents(spot) {
    var keyHandled = false;

    spot.input_field.bind("keydown.spotlite", function(e) {
      keyHandled = handleKeypress.call(spot, e);
    });

    spot.input_field.bind("keyup.spotlite focus.spotlite", function(e) {
      if (e.type === "keyup" && keyHandled) { return; }
      var ss = $(this).val();
      ss.length && spot.match_list.length ? spot.showMatches() : spot.match_list.hide();
      if (ss.length >= spot.threshold) {
        spot.cache = populateMatches.call(spot, ss);
        selectMatch.call(spot, 0);
        spot.current_val = ss;
      }
      keyHandled = false;
    });

    spot.result_list.children().each(function() {
      removeOnClick($(this));
    });

    $("body").live("click.spotlite", function(e) {
      if (!$.contains(spot.match_list[0], e.target) && !($(e.target).is(":input." + spot.class_prefix + "-input"))) {
        spot.match_list.hide();
      }
    });

  }

  function generatePool(data) {
    var spot = this,
        terms = data ? data : spot.pool,
        pool = [],
        match_item = {},
        words = [],
        i, j, tl, wl, term;
    for (i = 0, tl = terms.length; i < tl; i++) {
      words = [];
      if (typeof terms[i] === "object") {
        term = terms[i];
        for (t in term) {
          if (spot.bypass.length) {
            if ($.inArray(t, spot.bypass) == -1) {
              words = $.merge(words, cleanSplit(term[t]));
            }
          } else {
            words = $.merge(words, cleanSplit(term[t]));
          }
        }
      } else {
        words = cleanSplit(terms[i]);
      }
      for (j = 0, wl = words.length; j < wl; j++) {
        match_item.term = terms[i];
        match_item.search_term = words.slice(j).join(" ").toLowerCase();
        pool.push($.extend({}, match_item));
      }
    }
    spot.pool = pool;

    function cleanSplit(str) {
      return spot.sanitize($.trim(str)).split(" ");
    }
  }

  function populateMatches(ss) {
    var results = [],
        spot = this,
        new_cache = [],
        temp_term,
        val,
        item,
        clean_ss = spot.sanitize(ss).toLowerCase(),
        pool = spot.pool,
        current_results = [];
    spot.result_list.find("li").each(function() {
      current_results.push($(this).text());
    });
    if(ss.length > 1 && spot.current_val === ss.substring(0, ss.length-1)) {
      pool = spot.cache;
    } else {
      spot.cache = [];
    }
    spot.match_list.children().remove();
    for (var i = 0, pl = pool.length; i < pl; i++) {
      item = pool[i];
      if ($.trim(clean_ss).length && clean_ss === $.trim(item.search_term).substring(0, ss.length)) {
        new_cache.push(pool[i]);
        if ((results.length < spot.result_limit) &&
            ((spot.multiselect && $.inArray(item.term, current_results) < 0) || !spot.multiselect)) {
          if (typeof item.term === "object") {
            temp_term = $.extend({}, item.term);
            for (val in temp_term) {
              temp_term[val] = highlightInString.call(spot, ss, temp_term[val]);
            }
            results.push(spot.output(temp_term)[0]);
          } else {
            results.push(spot.output(highlightInString.call(spot, ss, item.term))[0]);
          }
        }
      }
    }
    if (results.length && ss.length) {
      for (var j = 0, rl = results.length; j < rl; j++) {
        if (!spot.match_list.find(":contains(" + $(results[j]).text() + ")").length) {
          spot.match_list.append(results[j]);
        }
      }
      spot.showMatches().children()
        .bind("mouseover.spotlite", function() {
          selectMatch.call(spot, $(this).index());
      }).bind("click", function() {
        addMatch.call(spot, $(this));
      });
    } else {
      spot.match_list.hide();
    }
    spot.match_count = results.length;
    return new_cache;
  }

  function selectMatch(num) {
    var spot = this;
    var $li = spot.match_list.children();
    if ($li.length) {
      $li.removeClass(spot.class_prefix + "-selected")[num].className += spot.class_prefix + "-selected";
    }
  }

  function highlightInString(ss, term) {
    var spot = this;
    term = ' ' + term;
    var found = spot.sanitize(term).toLowerCase().indexOf(' ' + spot.sanitize(ss).toLowerCase());
    if (found < 0) {
      return $.trim(term);
    }
    var to_markup = term.substr(found + 1, ss.length);
    var start = term.substr(0, found + 1);
    var end = term.substr(found + 1 + ss.length);
    return $.trim(start + '<b class="' + spot.class_prefix + '-highlighted">' + to_markup + '</b>' + end);
  }

  function addMatch($el) {
    var spot = this;
    if (spot.multiselect) {
      var hl = $el.find('.' + spot.class_prefix + '-highlighted');
      hl.replaceWith(hl.html());
      spot.result_list.append(removeOnClick($el.removeClass(spot.class_prefix + "-selected").unbind().detach()));
      spot.input_field.val('');
      spot.current_val = '';
    } else if ($el.length) {
      spot.input_field.val($el.text());
      spot.current_val = $el.text();
      $el.removeClass(spot.class_prefix + "-selected");
    }
    spot.match_list.hide().children().detach();
  }

  function handleKeypress(e) {
    var spot = this,
        keycode = e.keyCode,
        $ul = spot.match_list,
        $sel = $ul.find("." + spot.class_prefix + "-selected"),
        idx = $sel.index();
    if (keycode === 40 && (idx != $sel.siblings().length)) {
      selectMatch.call(this, idx + 1);
    } else if (keycode === 38 && (idx != 0)) {
      selectMatch.call(this, idx - 1);
    } else if (keycode === 27) {
      $ul.hide();
    } else if (keycode === 13) {
      e.preventDefault();
      addMatch.call(this, $sel);
    } else if (keycode === 9) {
      addMatch.call(this, $sel);
    } else {
      return false;
    }
    return true;
  }

  function removeOnClick($el) {
    return $el.bind("click.spotlite", function() {
      $(this).animate({ opacity: 0 }, {
        duration: 200,
        complete: function() {
          $(this).slideUp(200, function() {
            $(this).remove();
          });
        }
      });
    });
  }

})(jQuery);
