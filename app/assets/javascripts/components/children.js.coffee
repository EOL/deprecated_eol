{ div, ul, li, a } = React.DOM

@Children = React.createClass

  handleClick: (e, branch) ->
    if document.getElementById("expand_#{branch.id}").innerText == "+"
      @setState( "clicked_#{branch.id}" : true)
      document.getElementById("expand_#{branch.id}").innerText = "-"
    else
      @setState( "clicked_#{branch.id}" : false)
      document.getElementById("expand_#{branch.id}").innerText = "+"

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
              id: "expand_#{child.id}"
              onClick: @handleClick.bind(this,'click', child)
              '+'
          if @state && @state["clicked_#{child.id}"]
            div
              className: 'children'
              id: "children_#{child.id}"
              React.createElement Children, children: child.children, key: child.id