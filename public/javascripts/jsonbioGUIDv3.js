var bioGUIDspanName = "article";
var bioGUIDiconURL = "/images/bioGUID/";

var bioGUIDicon = new Array();
bioGUIDicon[0] = bioGUIDiconURL + "magnifier.png"; //search icon
bioGUIDicon[1] = bioGUIDiconURL + "ajax-loader.gif"; //loading or working icon
bioGUIDicon[2] = bioGUIDiconURL + "world_go.png"; //doi
bioGUIDicon[3] = bioGUIDiconURL + "g_scholar.png"; //Google icon
bioGUIDicon[4] = bioGUIDiconURL + "error.png"; //not understood
bioGUIDicon[5] = bioGUIDiconURL + "clock_red.png "; //timeout

var bioGUIDurl = "http://128.128.175.239/cgi-bin/parseref?output=json&q=";

function getElementsByClass(searchClass) {
	var classElements = new Array();
	var els = document.getElementsByTagName('*');
	var elsLen = els.length;
	var pattern = new RegExp('(^|\\s)'+searchClass+'(\\s|$)');
	for (i = 0, j = 0; i < elsLen; i++) {
		if ( pattern.test(els[i].className) ) {
			classElements[j] = els[i];
			j++;
		}
	}
	return classElements;
}

function updateReferences() {
	var imgholder = new Image();
	imgholder.src = bioGUIDicon[0];
	var aSpans = getElementsByClass(bioGUIDspanName);
	for(i=0;i<aSpans.length;i++){
		if ( aSpans[i].innerHTML.toLowerCase().indexOf('img') < 0 ) {
			aSpans[i].innerHTML = '<span id="bioGUIDref_' + i + '">' + aSpans[i].innerHTML + '</span> <span id="bioGUIDres_' + i + '"><a href="#" onclick="JavaScript:bioGUIDOpenURL(\'bioGUIDref_' + i + '\',\'bioGUIDres_' + i +'\');return false"><img id="bioGUIDimg_'+i+'" style="border:0px;height:16px;width:16px" alt="Search!" title="Search!"></a></span>';
			document.getElementById('bioGUIDimg_'+i).src=imgholder.src;
		}
	}	
}

var loader = new Object;
loader.callQueue = new Array();

loader.getJSON = function(objReference,objCallBackFnc,jsonUrl)
{
	var _index = loader.callQueue.length;
	loader.callQueue[_index] = new jsHandler(objReference,objCallBackFnc,_index);
	var elem = document.createElement("script");
	elem.id = "script" + _index;
	elem.src = jsonUrl + "&noCacheIE=" + (new Date()).getTime() + "&callback=loader.callQueue[" + _index +"].transferOO";
	document.body.appendChild(elem);
}  
 
function jsHandler()
{
	this.objReference = arguments[0];
	this.callBackFnc = arguments[1];
	this.scriptId = arguments[2];
}

jsHandler.prototype.transferOO = function()
{
	this.objReference.json = arguments[0];
	this.callBackFnc.call(this.objReference,arguments[0]);
	document.body.removeChild(document.getElementById("script" + this.scriptId));
	this.objReference = null;
	this.callBackFnc = null;
}

var bioGUID = new Object();

bioGUID.getDetails = function(ref)
{
	this.apiURL = bioGUIDurl + ref;
}

bioGUID.getDetails.prototype.load = function()
{
	var _ref = this;
	var _url = this.apiURL;
	loader.getJSON(_ref,_ref.displayResult,_url);
	var spinnerTimeout = setTimeout(function(){
	if (document.getElementById(_ref.outputId).getElementsByTagName("img")[0].src == bioGUIDicon[1]){
			document.getElementById(_ref.outputId).innerHTML = "<img src='" + bioGUIDicon[5] + "' style='border:0px;height:16px;width:16px' alt='Timeout - please try again later' title='Timeout - please try again later'>";
		}
		else{}
	},15000);
}

bioGUID.getDetails.prototype.displayResult = function()
{
	var _output = "";
	try{
		this.report = this.json.record;

		var doi = this.report.doi;
		var atitle = this.report.atitle;
		var glink = "http://scholar.google.com/scholar?q="+escape(atitle)+"&as_subj=bio";
	
		if (doi == null && atitle != null) {
			_output = '<a target=_blank href="' + glink + '"><img src="'+bioGUIDicon[3]+'" style="border:0px;height:16px;width:16px" alt="Search Google Scholar" title="Search Google Scholar"></a>';
		}
		else {
			var link = "http://dx.doi.org/"+doi;
			_output = '<a target=_blank href="'+link+'"><img src="'+bioGUIDicon[2]+'" style="border:0px;height:16px;width:16px" alt="To publisher..." title="To publisher..."></a>';
		}

        }
	catch(e){
		 _output = "<img src=" + bioGUIDicon[4]+ " style='border:0px;height:16px;width:16px' alt='Reference not Understood' title='Reference not Understood'>";
	}
	if (document.getElementById(this.outputId) != undefined){
		document.getElementById(this.outputId).innerHTML = _output;
	}
}

function Right(str, n){
    if (n <= 0) {
       return "";
    }
    else if (n > String(str).length) {
       return str;
    }
    else {
       var iLen = String(str).length;
       return String(str).substring(iLen, iLen - n);
    }
}

function bioGUIDOpenURL(ref,id)
{
	// browser check from: http://blog.coderlab.us/2006/04/18/the-textcontent-and-innertext-properties/
	var hasInnerText = (document.getElementsByTagName("body")[0].innerText !== undefined) ? true : false;
	var reftext = document.getElementById(ref);
		
	if(!hasInnerText) {
		var refurl = escape(reftext.textContent);
	}
	else {
		var refurl = escape(reftext.innerText);
	}

	//check length of escaped reference
	if (refurl.length >= 700) {
		alert('Sorry, this reference is too long.');
		return;
	}

	document.getElementById(id).innerHTML = '<img src="'+bioGUIDicon[1]+'" style="border:0px;height:16px;width:16px" alt="Finding reference..." title="Finding reference...">';
	var bioGUIDNew = new bioGUID.getDetails(refurl);
	bioGUIDNew.outputId = id;
	bioGUIDNew.load();
}