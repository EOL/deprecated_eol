              var g = new Bluff.Line('graph', "1000x600");
      g.theme_37signals();
      g.tooltips = true;
      g.title_font_size = "24px"
      g.legend_font_size = "12px"
      g.marker_font_size = "10px"

        g.title = 'Reek: code smells';
        g.data('ClassVariable', [22,25])
g.data('ControlCouple', [53,53])
g.data('DataClump', [16,14])
g.data('Duplication', [1519,1556])
g.data('IrresponsibleModule', [141,153])
g.data('LargeClass', [32,32])
g.data('LongMethod', [366,371])
g.data('LongParameterList', [14,12])
g.data('LowCohesion', [282,285])
g.data('NestedIterators', [92,106])
g.data('SimulatedPolymorphism', [46,47])
g.data('UncommunicativeName', [262,269])

        g.labels = {"0":"12/23","1":"1/28"};
        g.draw();
