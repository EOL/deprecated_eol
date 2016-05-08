{ div, ul, li, a } = React.DOM

@Navigate = React.createClass

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
    div
      className: 'tree'
      for branch in @props.tree
        ul
          className: 'branch'
          key: branch.id
          id: "branch_#{branch.id}"
          a
            className: 'name'
            branch.scientific_name
          if branch.children
            a 
              id: "expand_#{branch.id}"
              style: { marginLeft: '5px' }
              onClick: @handleClick.bind(this,'click', branch)
              '+'
          if @state && @state["clicked_#{branch.id}"]
            @renderChildren(branch)


 