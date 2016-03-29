var EoLMap              = {};
EoLMap.recs             = null;
EoLMap.map              = null;
EoLMap.markerClusterer  = null;
EoLMap.markers          = [];
EoLMap.infoWindow       = null;

var markerSpiderfier = null;    //for spiderfy
var statuz      = [];           //for back button
var statuz_all  = [];           //for next button
var initial_map = false;        //for original map

function clustersOnOff()
{
    if ($('goRadioText').innerHTML == "Clusters ON") {$('goRadioText').innerHTML = "Clusters OFF";}
    else                                             {$('goRadioText').innerHTML = "Clusters ON";}
    EoLMap.change();
}

function get_center_lat_long()
{
    var bound = new google.maps.LatLngBounds();
    EoLMap.recs = data.records;
    var numMarkers = EoLMap.recs.length;
    for (var i = 0; i < numMarkers; i++)
    {
      bound.extend( new google.maps.LatLng(EoLMap.recs[i].h, EoLMap.recs[i].i) ); //h=lat ; i=lon
    }
    return bound.getCenter();
}

EoLMap.init = function() {

  //start centering map
  center_latlong = get_center_lat_long()
  var latlng = new google.maps.LatLng(center_latlong.lat(), center_latlong.lng());
  //end centering map
  
  var options = {
    'zoom': 2,
    'center': latlng,
    'mapTypeId': google.maps.MapTypeId.ROADMAP,
    'scaleControl': true};

  EoLMap.map = new google.maps.Map($('map-canvas'), options);

  //start customized controls
  var centerControlDiv = document.createElement('div');
  var centerControl = new CenterControl(centerControlDiv, EoLMap.map, 1);
  centerControlDiv.index = 1;
  centerControlDiv.style['padding-top'] = '10px';
  EoLMap.map.controls[google.maps.ControlPosition.TOP_CENTER].push(centerControlDiv);
  //end customized controls

  EoLMap.recs = data.records;
  $('total_markers').innerHTML = data.actual + "<br>Plotted: " + data.count;
  
  
  EoLMap.map.enableKeyDragZoom();  //for key-drag-zoom
  
  //start spiderfy
  var spiderConfig = {keepSpiderfied: true, event: 'mouseover'};
  markerSpiderfier = new OverlappingMarkerSpiderfier(EoLMap.map, spiderConfig);
  //end spiderfy
  
  EoLMap.infoWindow = new google.maps.InfoWindow();
  EoLMap.showMarkers();
  google.maps.event.addListener(EoLMap.map, 'idle', function(){record_history();}); //for back-button    //other option for event 'tilesloaded'
  
};

EoLMap.showMarkers = function() {
  EoLMap.markers = [];

  if (EoLMap.markerClusterer) {
    EoLMap.markerClusterer.clearMarkers();
  }

  var panel = $('markerlist');
  panel.innerHTML = '';
  
  var numMarkers = EoLMap.recs.length;
  // $('total_markers').innerHTML = numMarkers;

  for (var i = 0; i < numMarkers; i++) {
    var titleText = EoLMap.recs[i].a; //catalogNumber
    if (titleText === '') {
      titleText = 'No catalog number';
    }

    var item = document.createElement('DIV');
    var title = document.createElement('A');
    title.href = '#';
    title.className = 'title';
    title.innerHTML = titleText;

    item.appendChild(title);
    panel.appendChild(item);

    var latLng = new google.maps.LatLng(EoLMap.recs[i].h, EoLMap.recs[i].i); //h=lat ; i=lon
    var marker = new google.maps.Marker({
      'position': latLng,
      'icon': "https://storage.googleapis.com/support-kms-prod/SNP_2752125_en_v0"
    });

    var fn = EoLMap.markerClickFunction(EoLMap.recs[i], latLng);
    google.maps.event.addListener(marker, 'click', fn);
    google.maps.event.addDomListener(title, 'click', fn);
    EoLMap.markers.push(marker);
    
    //start spiderfy
    markerSpiderfier.addMarker(marker); // Adds the Marker to OverlappingMarkerSpiderfier
    //end spiderfy
    
  }//end looping of markers
  
  //start spiderfy
  markerSpiderfier.addListener('click', function(marker, e) {EoLMap.infoWindow.open(EoLMap.map, marker);});
  markerx = EoLMap.markers;
  markerSpiderfier.addListener('spiderfy', function(markerx) {EoLMap.infoWindow.close();});
  //end spiderfy
  
  window.setTimeout(EoLMap.time, 0);
};

EoLMap.markerClickFunction = function(pic, latlng) {
  return function(e) {
    e.cancelBubble = true;
    e.returnValue = false;
    if (e.stopPropagation) {
      e.stopPropagation();
      e.preventDefault();
    }
    
    /*
    $header['a'] = "catalogNumber";
    $header['b'] = "sciname";
    $header['c'] = "publisher";
    $header['d'] = "publisher_id";
    $header['e'] = "dataset";
    $header['f'] = "dataset_id";
    $header['g'] = "gbifID";
    $header['h'] = "lat";
    $header['i'] = "lon";
    $header['j'] = "recordedBy";
    $header['k'] = "identifiedBy";
    $header['l'] = "pic_url";
    $header['m'] = "eventDate";
    */
    
    var title = pic.b;                                                                                                              //sciname
    var infoHtml = '<div class="info"><h3>' + title + '</h3>';
    if(pic.l)       {infoHtml += '<div class="info-body"><img src="' + pic.l + '" class="info-img"/></div><br/>';}                  //pic_url
    if(pic.a) {infoHtml += 'Catalog number: ' + pic.a + '<br/>';}                                                                   //catalogNumber
    infoHtml += 'Source portal: <a href="http://www.gbif.org/occurrence/' + pic.g + '" target="_blank">GBIF data</a>' + '<br/>' +   //gbifID
                'Publisher: <a href="http://www.gbif.org/publisher/' + pic.d + '" target="_blank">' + pic.c + '</a><br/>' +         //publisher_id & publisher
                'Dataset: <a href="http://www.gbif.org/dataset/' + pic.f + '" target="_blank">' + pic.e + '</a><br/>';              //dataset_id & dataset
    if(pic.j)   {infoHtml += 'Recorded by: ' + pic.j + '<br/>';}                                                                    //recordedBy
    if(pic.k) {infoHtml += 'Identified by: ' + pic.k + '<br/>';}                                                                    //identifiedBy
    if(pic.m) {infoHtml += 'Event date: ' + pic.m + '<br/>';}                                                                       //eventDate
    infoHtml += '</div>';
    
    
    /*
    var title = pic.sciname;
    var infoHtml = '<div class="info"><h3>' + title + '</h3>';
    if(pic.pic_url)       {infoHtml += '<div class="info-body"><img src="' + pic.pic_url + '" class="info-img"/></div><br/>';}
    if(pic.catalogNumber) {infoHtml += 'Catalog number: ' + pic.catalogNumber + '<br/>';}
    infoHtml += 'Source portal: <a href="http://www.gbif.org/occurrence/' + pic.gbifID + '" target="_blank">GBIF data</a>' + '<br/>' +
                'Publisher: <a href="http://www.gbif.org/publisher/' + pic.publisher_id + '" target="_blank">' + pic.publisher + '</a><br/>' +
                'Dataset: <a href="http://www.gbif.org/dataset/' + pic.dataset_id + '" target="_blank">' + pic.dataset + '</a><br/>';
    if(pic.recordedBy)   {infoHtml += 'Recorded by: ' + pic.recordedBy + '<br/>';}
    if(pic.identifiedBy) {infoHtml += 'Identified by: ' + pic.identifiedBy + '<br/>';}
    if(pic.eventDate) {infoHtml += 'Date recorded: ' + pic.eventDate + '<br/>';}
    infoHtml += '</div>';
    */
    
    EoLMap.infoWindow.setContent(infoHtml);
    EoLMap.infoWindow.setPosition(latlng);
    EoLMap.infoWindow.open(EoLMap.map);
  };
};

EoLMap.clear = function() {
  for (var i = 0, marker; marker = EoLMap.markers[i]; i++) {marker.setMap(null);}
};

EoLMap.change = function() {
  EoLMap.clear();
  EoLMap.showMarkers();
};

EoLMap.time = function() {
    if (!document.getElementById("goRadioText")) {EoLMap.markerClusterer = new MarkerClusterer(EoLMap.map, EoLMap.markers);}
    else
    {
        if ($('goRadioText').innerHTML == "Clusters ON") {
            EoLMap.markerClusterer = new MarkerClusterer(EoLMap.map, EoLMap.markers);
        } 
        else {
            for (var i = 0, marker; marker = EoLMap.markers[i]; i++) {marker.setMap(EoLMap.map);}
        }
    }
};
