{ div, ul, li, a } = React.DOM

@Children = React.createClass

  handleClick: (e, branch) ->
    if document.getElementById("expand_#{branch.id}").innerText == "+"
      @setState( "clicked_#{branch.id}" : true)
      document.getElementById("expand_#{branch.id}").innerText = "-"
    else
      @setState( "clicked_#{branch.id}" : false)
      document.getElementById("expand_#{branch.id}").innerText = "+"

  renderChildren: (branch) ->
    div
      className: 'children'
      id: "children_#{branch.id}"
      React.createElement Children, children: branch.children, key: branch.id

  render: ->
    ul
      className: 'branch'
      style: { marginLeft: '7px' }
      for child in @props.children
        li
          key: child.id
          a
            className: 'name'
            child.scientific_name
          if child.children
            a
              id: "expand_#{child.id}"
              style: { marginLeft: '5px' }
              onClick: @handleClick.bind(this,'click', child)
              '+'
          if @state && @state["clicked_#{child.id}"]
            @renderChildren(child)