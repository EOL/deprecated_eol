@Children = React.createClass
  render: ->
    React.DOM.ul
      className: 'branch'
      for child in @props.children
        React.DOM.li
          key: child.id
          React.DOM.a
            child.scientific_name
          if child.children
            React.DOM.a
              className: 'expand'
              '+'
          if child.children
            React.createElement Children, children: child.children, key: child.id