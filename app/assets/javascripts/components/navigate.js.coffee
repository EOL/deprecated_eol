{ div, ul, li, a } = React.DOM
@Navigate = React.createClass

  handleClick: (e, branch) ->
      @setState( "clicked_#{branch.id}" : true)

    



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
              className: 'expand'
              onClick: @handleClick.bind(this,'click', branch)
              '+'
          if @state && @state["clicked_#{branch.id}"]
            div
              className: 'children'
              id: "children_#{branch.id}"
              React.createElement Children, children: branch.children, key: branch.id


 