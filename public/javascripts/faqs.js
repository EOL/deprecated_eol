var plus = "url(/images/faqPlus.gif)";
var minus = "url(/images/faqMinus.gif)";
var padding = "14px";

function toggleDisplay(id){
	  var obj = document.getElementById(id);
		  if (obj !== undefined){
			  if (obj.style.display == "none"){
				obj.style.display = "block";
			}else{
				obj.style.display = "none";
			}			
		}		  
}

function toggleSign(lnk){
	if (lnk.style.backgroundImage == plus){
		lnk.style.backgroundImage = minus;
	}else if (lnk.style.backgroundImage == minus){
		lnk.style.backgroundImage = plus;
	}
}

function hasClass(obj, className){
	var classArray = obj.className.split(" ");
	for (var i in classArray){
		if (classArray[i] == className){
			return true;
		}
	}
	return false;
}

function collapseDL(id){
	if (document.getElementById) {
		  var lastId;
			var dl = document.getElementById(id);
				for (i=0; i<dl.childNodes.length; i++) {
				var node = dl.childNodes[i];
				if (node.nodeName=="DT") {
					for (j=0; j<node.childNodes.length; j++){
					   lnk = node.childNodes[j];
					   if (lnk.nodeName == "A"){
							   break;
					   }
					}
					lnk.id = id+i;
					lnk.style.backgroundImage = plus;
					lnk.style.backgroundRepeat = "no-repeat";
					lnk.style.backgroundPosition = "left center";
					lnk.style.paddingLeft = padding;					
					lnk.onclick = lnk.onkeyup = function(){
						toggleDisplay("dd" + this.id);
						toggleSign(this);
						return false;
					};
					lastId = lnk.id;
				}
				if (node.nodeName=="DD") {
					node.id = "dd" + lastId;
					node.style.display = "none";
				}
			}
		}	
}

function initDLTree(className){
	if (document.getElementById) {
		var lastId;
		var dls = document.getElementsByTagName("DL");
		for (var i=0; i<dls.length; i++){
			var dl = dls[i];
			if (className !== null && !hasClass (dl, className)){
				continue;
			}
			var id = dl.id;
			if (id === ""){
				id = "faqdl" + i;
				dl.id = id;
			}
			collapseDL(id);
		}		
	}	
}

function expandDLTree(className){
	if (!document.getElementById){
		return;
	}
	var dds = document.getElementsByTagName("DD");
	for (var i=0; i<dds.length; i++){
		var dd = dds[i];
		if (hasClass(dd.parentNode, className)){
			dd.style.display = "block";
		}
	}
	var lnks  = document.getElementsByTagName("A");
	for (var j=0; j<lnks.length; j++){
		var lnk = lnks[j];
		if (lnk.style.backgroundImage == plus && hasClass(lnk.parentNode.parentNode, className)){
			lnk.style.backgroundImage = minus;
		}
	}
}

document.observe("dom:loaded", function() {
  initDLTree("faqBlock");
});
