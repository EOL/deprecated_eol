//changes in clade
$(document).ready(function () {
  $('#taxon_name_id, #autocomplete_q').bind('change', function(event) {
    $.ajax({ url: "/advanced_search/update_attributes", dataType: "script"});
  });
});

(function ($) {

  // IE doesn't support trim
  if (typeof String.prototype.trim !== 'function') {
    String.prototype.trim = function() {
      return this.replace(/^\s+|\s+$/g, '');
    };
  }

  // combatting browsers that insist on display: block after fadeIn
  $.fn.fadeInline = function(options) {
    var defaults = {
          duration: 200,
          display:  'inline-block'
        },
        settings = $.extend(defaults, options);
    return this.each(function() {
      $(this).css({ opacity: 0, display: settings.display })
        .fadeTo(settings.duration, 1);
    });
  };

  // custom jQuery plugin to summarize form input
  $.fn.summarizeInput = function(options) {

    var defaults = {
          truncate:  0,
          panel:     $(this),
          container: $('<p/>', { 'class': 'summarize_input' }),
          wrapper:   $('<span/>'),
          exclude:   {}
          // using exclude { inputName: ['value', 'value'] } e.g:
          // { a: ['x', 'y'], b: [] }
          // exclude from summary input[name="a"] if this.value is x or y
          // exclude from summary input[name="b"] regardless of value
        },
        settings = $.extend(defaults, options);

    return this.each(function() {
      var labels  = $(this).find('label'),
          inputs  = $(this).find(':input'),
          summary = [];
          output  = '';

      inputs.each(function() {
        var name    = this.name,
            label   = $.grep(labels, function(l, i) {
              return $(l).attr('for') == name;
            })[0],
            value   = (this.type == 'select-one') ?
              $(this.selectedOptions).text() : this.value,
            exclude = typeof settings.exclude[name] != 'undefined' &&
              (settings.exclude[name].length === 0 ||
              $.inArray(this.value, settings.exclude[name]) === 0);

        if (value && !exclude) {
          summary.push([
            $(label).text(),
            (settings.truncate > 0 && value.length > settings.truncate) ?
              value.substr(0, settings.truncate) + '\u2026' : value
          ]);
        }
      });

      if (summary.length > 0) {
        for (var i in summary) {
          summary[i] = summary[i].join(': ');
        }
        settings.wrapper.text(summary.join('; ')).appendTo(settings.container);
        settings.container.hide().appendTo(settings.panel).fadeIn(500);
      }
    });
  };

  $(function() {

    (function(dataSearch){

      var vital = dataSearch.find('.vital'),
          watch = {
            q:    dataSearch.find('input[name="q"]'),
            min:  dataSearch.find('input[name="min"]'),
            max:  dataSearch.find('input[name="max"]')
          },
          unit = dataSearch.find('select[name="unit"]'),
          disabledPlaceholders = {
            q:   watch.q.data('disabled-placeholder'),
            min: watch.min.data('disabled-placeholder'),
            max: watch.max.data('disabled-placeholder')
          },
          taxonName = dataSearch.find('input[name="taxon_name"]'),
          valueRemovedPlaceholders = {
            taxonName: taxonName.data('value-removed-placeholder')
          };

      // add an extra submit button for convenience
      $('<fieldset/>', {
        class: 'prominent_actions',
        html: $('<legend/>', {
          class: 'assistive',
          text: 'Additional search submit'
        })}).append(dataSearch.find('#traitbank_search input[type="submit"]').clone()
        .attr('title', 'Search now or move on to add more search criteria'))
        .appendTo(vital);

      function adjustPlaceholders() {
        for (var name in watch) {
          if (watch[name].is(':disabled')) {
            if (watch[name].attr('placeholder') != disabledPlaceholders[name]) {
              watch[name].attr('placeholder', disabledPlaceholders[name]);
            }
          }
          else {
            if (watch[name].attr('placeholder') != watch[name].data('placeholder')) {
              watch[name].attr('placeholder', watch[name].data('placeholder'));
            }
          }
        }
      }

      function eitherOr(event) {
        event.stopImmediatePropagation();
        watch.min.prop('disabled', watch.q.val().trim());
        watch.max.prop('disabled', watch.q.val().trim());
        unit.prop('disabled', watch.q.val().trim());
        watch.q.prop('disabled',
          watch.min.val().trim() || watch.max.val().trim()
        );
        // sanity check in the highly unlikely event that we disabled everything
        if ( watch.min.is(':disabled') &&
             watch.max.is(':disabled') &&
             watch.q.is(':disabled') ) {
          watch.q(':disabled', false);
        }

        adjustPlaceholders();
      }

      // temporarily change placeholder if we removed taxon during search
      if (typeof valueRemovedPlaceholders.taxonName === 'string' &&
          valueRemovedPlaceholders.taxonName.length > 0) {
        taxonName.data('placeholder', taxonName.attr('placeholder'));
        taxonName.attr('placeholder', valueRemovedPlaceholders.taxonName);
        taxonName.one('keyup input paste', function() {
          // switch placeholder back once user starts to use the field
          taxonName.attr('placeholder', taxonName.data('placeholder'));
        });
      }

      // watch range and value inputs for changes and disable either or
      for (var name in watch) {
        // save original placeholder text, we'll need to get it back later
        watch[name].data('placeholder', watch[name].attr('placeholder'));
        watch[name].on('keyup input paste', {n: name}, eitherOr);
        watch[name].keyup();
      }

      // if we have some results show/hide extra fields
      if (dataSearch.data('results-total') > 0) {
        var extras    = dataSearch.find('.extras'),
            actions   = dataSearch.find('fieldset.actions'),
            link      = $('<a/>', { href: '#' }),
            summarize = {
              truncate:   50,
              panel:      vital,
              container:  $('<dl/>', { 'class': 'summarize_input' })
                .append($('<dt/>').append(extras.data('summary-intro'))),
              wrapper:   $('<dd/>'),
              exclude:   {
                sort: []
              }
            };

        link.hide().appendTo(vital);

        adjustSummarizeExclude = function() {
          if (!watch.min.val().trim() && !watch.max.val().trim()) {
            summarize.exclude.unit = [];
          }
          else if (typeof summarize.exclude.unit !== 'undefined') {
            delete summarize.exclude.unit;
          }
        };

        hide = function() {
          actions.fadeOut(200);
          adjustSummarizeExclude();
          extras.slideUp(500, function() {
            link.fadeOut(200, function() {
              $(this).text(extras.data('show')).fadeInline();
            });
          }).summarizeInput(summarize);
        };

        show = function() {
          extras.slideDown(500, function() {
            link.fadeOut(200, function() {
              $(this).text(extras.data('hide')).fadeInline();
            });
            summarize.container.fadeOut(500, function() {
              summarize.wrapper.remove();
              $(this).detach();
            });
          });
          actions.fadeIn(500);
        };

        $.each([link, summarize.container.find('a')], function(i, l) {
          l.accessibleClick(function() {
            // The following is considered invalid by jshint, but I don't like alternatives:
            extras.is(':visible') ? hide() : show();
            return false;
          });
        });

        hide();
      }

    })($('#advanced_search'));
    limit_search_summaries();
  });
}(jQuery));

var limit_search_summaries = function(known_uri_id) {
  var summaryDiv = $('.search_summary:has(ul.values)');
  if(summaryDiv.find('li').length > 9) {
    summaryDiv.find('li:gt(8)').slideUp(500);
    var numberToHide = summaryDiv.find('li').length - 9;
    var linkLabel = 'Show ' + numberToHide + ' more';
    var link = $('<a href="#">').text(linkLabel);
    // add some actions to this link
    link.on('click', function(e) {
      e.preventDefault();
      if($(this).attr('data-open') === 'true') {
        summaryDiv.find('li:gt(8)').slideUp(500, function() {
          link.text(linkLabel);
          link.attr('data-open', 'false');
        });
      } else {
        summaryDiv.find('li:gt(8)').slideDown(500, function() {
          link.text('Hide');
          link.attr('data-open', 'true');
        });
      }
    });
    // finally add this new link with actions to the page
    summaryDiv.append($('<span class="more"></span>').append(link));
  }
};
