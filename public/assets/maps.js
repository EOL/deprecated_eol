function clustersOnOff(){$("goRadioText").innerHTML="Clusters ON"==$("goRadioText").innerHTML?"Clusters OFF":"Clusters ON",EoLMap.change()}function get_center_lat_long(){var e=new google.maps.LatLngBounds;EoLMap.recs=data.records;for(var t=EoLMap.recs.length,a=0;t>a;a++)e.extend(new google.maps.LatLng(EoLMap.recs[a].h,EoLMap.recs[a].i));return e.getCenter()}function $(e){return document.getElementById(e)}function goFullScreen(){currCenter=EoLMap.map.getCenter();var e=document.getElementById("gmap");document.fullscreenElement||document.mozFullScreenElement||document.webkitFullscreenElement||document.msFullscreenElement?($("goFullText").innerHTML="Fullscreen OFF","Panel ON"==$("goPanelText").innerHTML?($("panel").style.height="500px",$("panel").style.width="200px",$("map-canvas").style.height="500px",$("map-canvas").style.width="700px"):($("panel").style.height="0px",$("panel").style.width="0px",$("map-canvas").style.height="500px",$("map-canvas").style.width="900px"),document.exitFullscreen?document.exitFullscreen():document.msExitFullscreen?document.msExitFullscreen():document.mozCancelFullScreen?document.mozCancelFullScreen():document.webkitExitFullscreen&&(e.style.width="",document.webkitExitFullscreen())):($("goFullText").innerHTML="Fullscreen ON","Panel ON"==$("goPanelText").innerHTML?($("panel").style.height="100%",$("panel").style.width="17%",$("map-canvas").style.height="100%",$("map-canvas").style.width="83%"):($("panel").style.height="0px",$("panel").style.width="0px",$("map-canvas").style.height="100%",$("map-canvas").style.width="100%"),e.requestFullscreen?e.requestFullscreen():e.msRequestFullscreen?e.msRequestFullscreen():e.mozRequestFullScreen?e.mozRequestFullScreen():e.webkitRequestFullscreen&&(e.style.width="100%",e.style.height="100%",e.webkitRequestFullscreen())),google.maps.event.trigger(EoLMap.map,"resize"),EoLMap.map.setCenter(currCenter)}function exitHandler(){if(is_full_screen){if(!document.webkitIsFullScreen){$("goFullText").innerHTML="Fullscreen OFF";var e=document.getElementById("gmap");e.style.width=""}document.mozFullScreen&&($("goFullText").innerHTML="Fullscreen ON")}is_full_screen()||("Panel ON"==$("goPanelText").innerHTML?($("panel").style.height="500px",$("panel").style.width="200px",$("map-canvas").style.height="500px",$("map-canvas").style.width="700px"):($("map-canvas").style.height="500px",$("map-canvas").style.width="900px")),google.maps.event.trigger(EoLMap.map,"resize"),EoLMap.map.setCenter(currCenter)}function is_full_screen(){var e=document.getElementById("gmap");if(e.requestFullscreen);else if(e.msRequestFullscreen){if(1==document.msFullscreenElement)return!0}else if(e.mozRequestFullScreen){if(1==document.mozFullScreen)return!0}else if(e.webkitRequestFullscreen&&1==document.webkitIsFullScreen)return!0;return!1}function panelShowHide(){$("goPanelText").innerHTML="Panel ON"==$("goPanelText").innerHTML?"Panel OFF":"Panel ON",is_full_screen()?($("map-canvas").style.height="100%","Panel ON"==$("goPanelText").innerHTML?($("panel").style.width="17%",$("panel").style.height="100%",$("map-canvas").style.width="83%"):($("panel").style.width="0px",$("panel").style.height="0px",$("map-canvas").style.width="100%")):($("map-canvas").style.height="500px","Panel ON"==$("goPanelText").innerHTML?($("panel").style.width="200px",$("panel").style.height="500px",$("map-canvas").style.width="700px"):($("panel").style.width="0px",$("panel").style.height="0px",$("map-canvas").style.width="900px")),currCenter=EoLMap.map.getCenter(),google.maps.event.trigger(EoLMap.map,"resize"),EoLMap.map.setCenter(currCenter)}function record_history(){var e={};e.center=EoLMap.map.getCenter(),e.zoom=EoLMap.map.getZoom(),e.mapTypeId=EoLMap.map.getMapTypeId(),statuz.push(e),statuz_all.push(e),initial_map||(initial_map=e),currCenter=EoLMap.map.getCenter()}function CenterControl(e,t,a){var n=document.createElement("div");n.id="goBackUI",n.title="Go back one step",e.appendChild(n);var l=document.createElement("div");l.id="goBackText",l.innerHTML="Go Back",n.appendChild(l);var r=document.createElement("div");r.id="goNextUI",r.title="Move forward one step",e.appendChild(r);var o=document.createElement("div");o.id="goNextText",o.innerHTML="Move Next",r.appendChild(o);var i=document.createElement("div");i.id="goOrigUI",i.title="Back to original map",e.appendChild(i);var p=document.createElement("div");if(p.id="goOrigText",p.innerHTML="Initial Map",i.appendChild(p),1==a){var s=document.createElement("div");s.id="goRadioUI",s.title="Toggle Clustering",e.appendChild(s);var c=document.createElement("div");c.id="goRadioText",c.innerHTML="Clusters ON",s.appendChild(c),s.addEventListener("click",function(){clustersOnOff()})}var d=document.createElement("div");d.id="goPanelUI",d.title="Toggle Panel",e.appendChild(d);var m=document.createElement("div");m.id="goPanelText",m.innerHTML="Panel OFF",d.appendChild(m);var u=document.createElement("div");u.id="goFullUI",u.title="Toggle Fullscreen",e.appendChild(u);var g=document.createElement("div");g.id="goFullText",g.innerHTML="Fullscreen OFF",u.appendChild(g),n.addEventListener("click",function(){EoLMap.back()}),r.addEventListener("click",function(){EoLMap.next()}),i.addEventListener("click",function(){EoLMap.map.setOptions(initial_map),statuz=[],statuz_all=[]}),d.addEventListener("click",function(){panelShowHide()}),u.addEventListener("click",function(){goFullScreen()})}var EoLMap={};EoLMap.recs=null,EoLMap.map=null,EoLMap.markerClusterer=null,EoLMap.markers=[],EoLMap.infoWindow=null;var markerSpiderfier=null,statuz=[],statuz_all=[],initial_map=!1;EoLMap.init=function(){center_latlong=get_center_lat_long();var e=new google.maps.LatLng(center_latlong.lat(),center_latlong.lng()),t={zoom:2,center:e,mapTypeId:google.maps.MapTypeId.ROADMAP,scaleControl:!0};EoLMap.map=new google.maps.Map($("map-canvas"),t);{var a=document.createElement("div");new CenterControl(a,EoLMap.map,1)}a.index=1,a.style["padding-top"]="10px",EoLMap.map.controls[google.maps.ControlPosition.TOP_CENTER].push(a),EoLMap.recs=data.records,$("total_markers").innerHTML=data.actual+"<br>Plotted: "+data.count,EoLMap.map.enableKeyDragZoom();var n={keepSpiderfied:!0,event:"mouseover"};markerSpiderfier=new OverlappingMarkerSpiderfier(EoLMap.map,n),EoLMap.infoWindow=new google.maps.InfoWindow,EoLMap.showMarkers(),google.maps.event.addListener(EoLMap.map,"idle",function(){record_history()})},EoLMap.showMarkers=function(){EoLMap.markers=[],EoLMap.markerClusterer&&EoLMap.markerClusterer.clearMarkers();var e=$("markerlist");e.innerHTML="";for(var t=EoLMap.recs.length,a=0;t>a;a++){var n=EoLMap.recs[a].a;""===n&&(n="No catalog number");var l=document.createElement("DIV"),r=document.createElement("A");r.href="#",r.className="title",r.innerHTML=n,l.appendChild(r),e.appendChild(l);var o=new google.maps.LatLng(EoLMap.recs[a].h,EoLMap.recs[a].i),i=new google.maps.Marker({position:o,icon:"https://storage.googleapis.com/support-kms-prod/SNP_2752125_en_v0"}),p=EoLMap.markerClickFunction(EoLMap.recs[a],o);google.maps.event.addListener(i,"click",p),google.maps.event.addDomListener(r,"click",p),EoLMap.markers.push(i),markerSpiderfier.addMarker(i)}markerSpiderfier.addListener("click",function(e){EoLMap.infoWindow.open(EoLMap.map,e)}),markerx=EoLMap.markers,markerSpiderfier.addListener("spiderfy",function(){EoLMap.infoWindow.close()}),window.setTimeout(EoLMap.time,0)},EoLMap.markerClickFunction=function(e,t){return function(a){a.cancelBubble=!0,a.returnValue=!1,a.stopPropagation&&(a.stopPropagation(),a.preventDefault());var n=e.b,l='<div class="info"><h3>'+n+"</h3>";e.l&&(l+='<div class="info-body"><img src="'+e.l+'" class="info-img"/></div><br/>'),e.a&&(l+="Catalog number: "+e.a+"<br/>"),l+='Source portal: <a href="http://www.gbif.org/occurrence/'+e.g+'" target="_blank">GBIF data</a><br/>Publisher: <a href="http://www.gbif.org/publisher/'+e.d+'" target="_blank">'+e.c+'</a><br/>Dataset: <a href="http://www.gbif.org/dataset/'+e.f+'" target="_blank">'+e.e+"</a><br/>",e.j&&(l+="Recorded by: "+e.j+"<br/>"),e.k&&(l+="Identified by: "+e.k+"<br/>"),e.m&&(l+="Event date: "+e.m+"<br/>"),l+="</div>",EoLMap.infoWindow.setContent(l),EoLMap.infoWindow.setPosition(t),EoLMap.infoWindow.open(EoLMap.map)}},EoLMap.clear=function(){for(var e,t=0;e=EoLMap.markers[t];t++)e.setMap(null)},EoLMap.change=function(){EoLMap.clear(),EoLMap.showMarkers()},EoLMap.time=function(){if(document.getElementById("goRadioText"))if("Clusters ON"==$("goRadioText").innerHTML)EoLMap.markerClusterer=new MarkerClusterer(EoLMap.map,EoLMap.markers);else for(var e,t=0;e=EoLMap.markers[t];t++)e.setMap(EoLMap.map);else EoLMap.markerClusterer=new MarkerClusterer(EoLMap.map,EoLMap.markers)};var currCenter="";document.addEventListener&&(document.addEventListener("webkitfullscreenchange",exitHandler,!1),document.addEventListener("mozfullscreenchange",exitHandler,!1),document.addEventListener("fullscreenchange",exitHandler,!1),document.addEventListener("MSFullscreenChange",exitHandler,!1)),EoLMap.back=function(){if(statuz.length>1){statuz.pop();var e=statuz.pop();EoLMap.map.setOptions(e),JSON.stringify(e)==JSON.stringify(initial_map)&&(statuz=[],statuz_all=[])}},EoLMap.next=function(){if(statuz_all.length>1){statuz_all.pop();var e=statuz_all.pop();EoLMap.map.setOptions(e),JSON.stringify(e)==JSON.stringify(initial_map)&&(statuz=[],statuz_all=[])}};