              var g = new Bluff.Line('graph', "1000x600");
      g.theme_37signals();
      g.tooltips = true;
      g.title_font_size = "24px"
      g.legend_font_size = "12px"
      g.marker_font_size = "10px"

        g.title = 'Flay: duplication';
        g.data('flay', [244,1754,2288]);
        g.labels = {"0":"12/23","1":"1/28","2":"6/24"};
        g.draw();
