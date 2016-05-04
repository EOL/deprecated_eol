
@Navigate = React.createClass
    render: ->
      React.DOM.div
        className: 'tree'
        for branch in @props.tree
          React.DOM.ul
            className: 'branch'
            key: branch.id
            React.DOM.a
              className: 'name'
              branch.scientific_name
            if branch.children
              React.DOM.a
                className: 'expand'
                id: "expand_#{branch.id}"
                '+'
            if branch.children
              React.createElement Children, children: branch.children, key: branch.id

 