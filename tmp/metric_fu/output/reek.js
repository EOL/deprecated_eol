              var g = new Bluff.Line('graph', "1000x600");
      g.theme_37signals();
      g.tooltips = true;
      g.title_font_size = "24px"
      g.legend_font_size = "12px"
      g.marker_font_size = "10px"

        g.title = 'Reek: code smells';
        g.data('ClassVariable', [22])
g.data('ControlCouple', [53])
g.data('DataClump', [16])
g.data('Duplication', [1519])
g.data('IrresponsibleModule', [141])
g.data('LargeClass', [32])
g.data('LongMethod', [366])
g.data('LongParameterList', [14])
g.data('LowCohesion', [282])
g.data('NestedIterators', [92])
g.data('SimulatedPolymorphism', [46])
g.data('UncommunicativeName', [262])

        g.labels = {"0":"12/23"};
        g.draw();
