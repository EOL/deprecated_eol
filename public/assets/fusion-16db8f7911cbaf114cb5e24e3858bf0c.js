function select_change(){var e,a=document.getElementById("heatmap_radio"),o=document.getElementById("heatmap_label"),r=document.getElementById("select_publisher").value.replace(/'/g,"\\'");"--ALL--"!=r?(e="'publisher' = '"+r+"'",a.checked=!1,layer_0.setOptions({heatmap:{enabled:!1}}),a.disabled=!0,o.style.color="gray"):(a.disabled=!1,o.style.color="black"),layer_0.setOptions({query:{select:"'location'",from:data.tableID,where:e}})}function add_publishers(){var e=document.getElementById("select_publisher");publishers=data.publishers;for(var a=0;a<publishers.length;a++){var o=document.createElement("option");o.value=publishers[a],o.innerHTML=publishers[a],e.appendChild(o)}}var EoLMap={};EoLMap.map=null;var layer_0,statuz=[],statuz_all=[],initial_map=!1;EoLMap.init=function(){EoLMap.map=new google.maps.Map(document.getElementById("map-canvas"),{center:new google.maps.LatLng(data.center_lat,data.center_lon),zoom:3,mapTypeId:google.maps.MapTypeId.ROADMAP,scaleControl:!0});{var e=document.createElement("div");new CenterControl(e,EoLMap.map,2)}e.index=1,e.style["padding-top"]="10px",EoLMap.map.controls[google.maps.ControlPosition.TOP_CENTER].push(e),EoLMap.map.enableKeyDragZoom(),layer_0=new google.maps.FusionTablesLayer({query:{select:"'location'",from:data.tableID},map:EoLMap.map,heatmap:{enabled:!1}}),google.maps.event.addDomListener(document.getElementById("heatmap_radio"),"click",function(){var e=document.getElementById("heatmap_radio");layer_0.setOptions({heatmap:{enabled:e.checked}})}),document.getElementById("heatmap_radio").checked=!1,document.getElementById("heatmap_radio").disabled=!1,add_publishers(),google.maps.event.addListener(EoLMap.map,"idle",function(){record_history()})};