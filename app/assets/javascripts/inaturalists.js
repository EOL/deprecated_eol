function initialize(url) {
  var mapCanvas = document.getElementById('map-canvas');
  var mapOptions = {
    center: new google.maps.LatLng(44.5403, -78.5463),
    zoom: 3,
    mapTypeId: google.maps.MapTypeId.ROADMAP
  }
  var map = new google.maps.Map(mapCanvas, mapOptions)
  var georssLayer = new google.maps.KmlLayer({
    url: url
  });
  georssLayer.setMap(map);
}