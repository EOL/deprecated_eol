{ div, ul, li, a } = React.DOM

@Children = React.createClass

  handleClick: (branch) ->
    if document.getElementById("expand_#{branch.id}").innerText == "+"
      @setState( "clicked_#{branch.id}" : true)
      document.getElementById("expand_#{branch.id}").innerText = "-"
    else
      @setState( "clicked_#{branch.id}" : false)
      document.getElementById("expand_#{branch.id}").innerText = "+"

  showImg: (branch) ->
    document.getElementById('title').innerText = branch.scientific_name
    if branch.thumbnail
      document.getElementById('speciesImg').src = branch.thumbnail
    else
      document.getElementById('speciesImg').src = null
      document.getElementById('speciesImg').alt = "Image is not available for \"#{branch.scientific_name} \""

  renderChildren: (branch) ->
    React.createElement Children, branch: branch, key: branch.id

  render: ->
    ul
      className: 'branch'
      key: @props.branch.id
      style: { marginLeft: '7px' }
      a
        className: 'name'
        onClick: @showImg.bind(this, @props.branch)
        @props.branch.scientific_name
      a
        id: "expand_#{@props.branch.id}"
        style: { marginLeft: '5px' }
        onClick: @handleClick.bind(this, @props.branch)
        '+'
      if @state && @state["clicked_#{@props.branch.id}"]
        for child in @props.branch.children
          @renderChildren(child)