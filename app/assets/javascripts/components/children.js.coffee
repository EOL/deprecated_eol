{ ul, li, a } = React.DOM
@Children = React.createClass
  render: ->
    ul
      className: 'branch'
      for child in @props.children
        li
          key: child.id
          a
            child.scientific_name
          if child.children
            a
              className: 'expand'
              '+'
          if child.children
            React.createElement Children, children: child.children, key: child.id