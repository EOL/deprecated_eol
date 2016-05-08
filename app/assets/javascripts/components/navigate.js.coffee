{ div, ul, li, a, h3 , center, img} = React.DOM
sidebarStyle = {
   marginRight: '150px'
   display: 'inline-block'
   marginLeft: '30px'
   padding: '10px 15px'
   width: '300px'
   float: 'right'
}
treeStyle = {
  marginLeft: '100px'
  fontSize: '15px'
  marginTop: '10px'
  display: 'inline-block'
}

@Navigate = React.createClass

  render: ->
    div
      className: 'content'
      div
        className: 'sidebar'
        style: sidebarStyle
        h3
          id: 'title'
          'Select species on the left to view the img'
        div
          center
            img
              id: 'speciesImg'
      div
        className: 'tree'
        style: treeStyle
        for branch in @props.tree
          React.createElement Children, branch: branch, key: branch.id
       
   