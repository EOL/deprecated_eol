function $(element) {return document.getElementById(element);}

var currCenter = "";

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


function goFullScreen()
{
    currCenter = EoLMap.map.getCenter();
    
    var elem = document.getElementById("gmap"); //gmap or map-container
    if (!document.fullscreenElement && !document.mozFullScreenElement && !document.webkitFullscreenElement && !document.msFullscreenElement )
    {
        $('goFullText').innerHTML = "Fullscreen ON";

        if ($('goPanelText').innerHTML == "Panel ON") {
            $('panel').style.height      = "100%";
            $('panel').style.width       = "17%";
            $('map-canvas').style.height = "100%";
            $('map-canvas').style.width  = "83%";
        }
        else {
            $('panel').style.height      = "0px";
            $('panel').style.width       = "0px";
            $('map-canvas').style.height = "100%";
            $('map-canvas').style.width  = "100%";
        }

        if      (elem.requestFullscreen)      {elem.requestFullscreen();}
        else if (elem.msRequestFullscreen)    {elem.msRequestFullscreen();}
        else if (elem.mozRequestFullScreen)   {elem.mozRequestFullScreen();}
        else if (elem.webkitRequestFullscreen) {
            elem.style.width = "100%";
            elem.style.height = "100%";
            elem.webkitRequestFullscreen(); //Element.ALLOW_KEYBOARD_INPUT
        }
    }
    else
    {
          $('goFullText').innerHTML = "Fullscreen OFF";
          if ($('goPanelText').innerHTML == "Panel ON")
          {
              $('panel').style.height      = "500px";
              $('panel').style.width       = "200px"; //400
              $('map-canvas').style.height = "500px";
              $('map-canvas').style.width  = "700px"; //800
          }
          else
          {
              $('panel').style.height      = "0px";
              $('panel').style.width       = "0px";
              $('map-canvas').style.height = "500px";
              $('map-canvas').style.width  = "900px"; //1200
          }

          if      (document.exitFullscreen) {document.exitFullscreen();}
          else if (document.msExitFullscreen) {document.msExitFullscreen();}
          else if (document.mozCancelFullScreen) {document.mozCancelFullScreen();}
          else if (document.webkitExitFullscreen) {
            elem.style.width = "";
            document.webkitExitFullscreen();
          }
    }
    
    google.maps.event.trigger(EoLMap.map, 'resize');
    EoLMap.map.setCenter(currCenter);
}

// start: listeners for fullscreenchanges
if (document.addEventListener) {
    document.addEventListener('webkitfullscreenchange', exitHandler, false);
    document.addEventListener('mozfullscreenchange', exitHandler, false);
    document.addEventListener('fullscreenchange', exitHandler, false);
    document.addEventListener('MSFullscreenChange', exitHandler, false);
}
function exitHandler() {
    
    if(is_full_screen)
    {
        if(!document.webkitIsFullScreen) {
            $('goFullText').innerHTML = "Fullscreen OFF";
            var elem = document.getElementById("gmap"); //gmap or map-container
            elem.style.width = "";
        }
        if(document.mozFullScreen) $('goFullText').innerHTML = "Fullscreen ON";
    }
    
    if(!is_full_screen()) {
        if ($('goPanelText').innerHTML == "Panel ON") {
            $('panel').style.height      = "500px";
            $('panel').style.width       = "200px"; //400
            $('map-canvas').style.height = "500px";
            $('map-canvas').style.width  = "700px"; //800
        }
        else {
            $('map-canvas').style.height = "500px";
            $('map-canvas').style.width  = "900px"; //1200
        }
    }
    
    google.maps.event.trigger(EoLMap.map, 'resize');
    EoLMap.map.setCenter(currCenter);
}
// end: listeners for fullscreenchanges

function is_full_screen()
{
    var elem = document.getElementById("gmap"); //gmap or map-container
    if      (elem.requestFullscreen) {}
    else if (elem.msRequestFullscreen) {
        if (document.msFullscreenElement == true) return true;
    } 
    else if (elem.mozRequestFullScreen) {
        if (document.mozFullScreen == true) return true;
    }
    else if (elem.webkitRequestFullscreen) {
        if (document.webkitIsFullScreen == true) return true;
    }
    return false;
}

function panelShowHide()
{
    if ($('goPanelText').innerHTML == "Panel ON") $('goPanelText').innerHTML = "Panel OFF";
    else                                          $('goPanelText').innerHTML = "Panel ON";
    
    if (is_full_screen())
    {
        $('map-canvas').style.height = "100%";
        if ($('goPanelText').innerHTML == "Panel ON")
        {
            $('panel').style.width       = "17%";
            $('panel').style.height      = "100%";
            $('map-canvas').style.width  = "83%";
        }
        else
        {
            $('panel').style.width       = "0px";
            $('panel').style.height      = "0px";
            $('map-canvas').style.width  = "100%";
        }
    }
    else //not full screen
    {
        $('map-canvas').style.height = "500px";
        if ($('goPanelText').innerHTML == "Panel ON")
        {
            $('panel').style.width       = "200px"; //400
            $('panel').style.height      = "500px";
            $('map-canvas').style.width  = "700px"; //800
        }
        else
        {
            $('panel').style.width      = "0px";
            $('panel').style.height     = "0px";
            $('map-canvas').style.width = "900px"; //1200
        }
    }

    currCenter = EoLMap.map.getCenter();
    google.maps.event.trigger(EoLMap.map, 'resize');
    EoLMap.map.setCenter(currCenter);
}

//start back button
function record_history()
{
    var current = {};
    current.center = EoLMap.map.getCenter();
    current.zoom = EoLMap.map.getZoom();
    current.mapTypeId = EoLMap.map.getMapTypeId();
    statuz.push(current);
    statuz_all.push(current);
    if(!initial_map) initial_map = current;
    currCenter = EoLMap.map.getCenter();
}
EoLMap.back = function()
{
    if(statuz.length > 1) {
        statuz.pop();
        var current = statuz.pop();
        EoLMap.map.setOptions(current);
        if(JSON.stringify(current) == JSON.stringify(initial_map)){
            statuz = [];
            statuz_all = [];
        }
    }
}
EoLMap.next = function()
{
    if(statuz_all.length > 1) {
        statuz_all.pop();
        var current = statuz_all.pop();
        EoLMap.map.setOptions(current);
        if(JSON.stringify(current) == JSON.stringify(initial_map)){
            statuz = [];
            statuz_all = [];
        }
    }
}
//end back button

//start customized controls
function CenterControl(controlDiv, map, ctrl_type) {
    
    // Set GO BACK button
    var goBackUI = document.createElement('div');
    goBackUI.id = 'goBackUI';                       //.id here is used in HTML <style>
    goBackUI.title = 'Go back one step';
    controlDiv.appendChild(goBackUI);
    // CSS for text
    var goBackText = document.createElement('div');
    goBackText.id = 'goBackText';
    goBackText.innerHTML = 'Go Back';
    goBackUI.appendChild(goBackText);

    // Set MOVE NEXT button
    var goNextUI = document.createElement('div');
    goNextUI.id = "goNextUI";
    goNextUI.title = 'Move forward one step';
    controlDiv.appendChild(goNextUI);
    // CSS for text
    var goNextText = document.createElement('div');
    goNextText.id = 'goNextText';
    goNextText.innerHTML = 'Move Next';
    goNextUI.appendChild(goNextText);

    // Set Original pos button
    var goOrigUI = document.createElement('div');
    goOrigUI.id = "goOrigUI";
    goOrigUI.title = 'Back to original map';
    controlDiv.appendChild(goOrigUI);
    // CSS for text
    var goOrigText = document.createElement('div');
    goOrigText.id = 'goOrigText';
    goOrigText.innerHTML = 'Initial Map';
    goOrigUI.appendChild(goOrigText);

    if(ctrl_type == 1) //for Cluster maps
    {
        // Set Cluster button
        var goRadioUI = document.createElement('div');
        goRadioUI.id = "goRadioUI";
        goRadioUI.title = 'Toggle Clustering';
        controlDiv.appendChild(goRadioUI);
        // CSS for text
        var goRadioText = document.createElement('div');
        goRadioText.id = 'goRadioText';
        goRadioText.innerHTML = 'Clusters ON';
        goRadioUI.appendChild(goRadioText);

        // Set up the click event listener
        goRadioUI.addEventListener('click', function() {clustersOnOff();});
    }

    // Set Panel button
    var goPanelUI = document.createElement('div');
    goPanelUI.id = "goPanelUI";
    goPanelUI.title = 'Toggle Panel';
    controlDiv.appendChild(goPanelUI);
    // CSS for text
    var goPanelText = document.createElement('div');
    goPanelText.id = 'goPanelText';
    goPanelText.innerHTML = 'Panel OFF';
    goPanelUI.appendChild(goPanelText);

    // Set Fullscreen button
    var goFullUI = document.createElement('div');
    goFullUI.id = "goFullUI";
    goFullUI.title = 'Toggle Fullscreen';
    controlDiv.appendChild(goFullUI);
    // CSS for text
    var goFullText = document.createElement('div');
    goFullText.id = 'goFullText';
    goFullText.innerHTML = 'Fullscreen OFF';
    goFullUI.appendChild(goFullText);

    // Set up the click event listener
    goBackUI.addEventListener('click', function() {EoLMap.back();});
    goNextUI.addEventListener('click', function() {EoLMap.next();});
    goOrigUI.addEventListener('click', function() {EoLMap.map.setOptions(initial_map);
        statuz = [];
        statuz_all = [];
    });
    goPanelUI.addEventListener('click', function() {panelShowHide();});
    goFullUI.addEventListener('click', function() {goFullScreen();});
}
//end customized controls
