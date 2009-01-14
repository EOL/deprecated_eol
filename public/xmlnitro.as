//--------------------------------------------------
// XMLnitro v 2.1
//--------------------------------------------------
// Branden J. Hall
// Fig Leaf Software
// October 1, 2001
//
// Thanks to Colin Moock for good whitespace info
//--------------------------------------------------
// This file simply replaces the built-in parseXML
// method.  In doing so it increases the speed of
// XML parsing 70-120% (dependent on file size).
// In addition, the ignoreWhite property now works
// in all versions of the Flash 5 plugin and no
// just the R41/42 versions. In order to do such
// this parser removes all text from mixed content
// nodes (i.e. nodes that contain both child nodes
// and child text nodes). This code is Flash 5 
// specific so it makes sure that the user has only
// a Flash 5 plugin.
//--------------------------------------------------
Object.version = getVersion().split(",");
Object.majorVersion = int(substring(Object.version[0],Object.version[0].length, 1));
Object.minorVersion = int(Object.version[2]);

if (Object.majorVersion == 5){
	XML.prototype.checkEmpty = function(text){
		var max = text.length;
		var empty = true;
		for (var i=0;i<max;++i){
			if (ord(substring(text, i+i, 1))>32){
				empty = false;
				break;
			}
		}
		return empty;
	}
	XML.prototype.parseXML = function(str){
		this.firstChild.removeNode();
		var treePtr = this;
		var tags = new Array();
		var textNode = null;
		if (Object.minorVersion == 30){
			this.status = ASnative(300, 0)(str, tags);
		}else{
			this.status = ASnative(300, 0)(str, tags, false);
		}
		if (this.status == 0){
			var curr;
			var i=0;
			var max = tags.length;
			if (this.ignoreWhite){
				while (i<max){
					curr = tags[i];
					if (curr.type == 1){
						if (curr.value == "/"+treePtr.nodeName){
							treePtr = treePtr.parentNode;
						}else{
							treePtr.appendChild(this.createElement(curr.value));
							treePtr = treePtr.lastChild;
							treePtr.attributes = curr.attrs;
							if (curr.empty){
								treePtr = treePtr.parentNode;
							}
						}
					}else{
						if (curr.type == 3){
							if (!this.checkEmpty(curr.value)){
								treePtr.appendChild(this.createTextNode(curr.value));
							}
						}else{
							if (curr.type == 6){
								treePtr.appendChild(this.createTextNode(curr.value));
							}else{
								if (curr.type == 4){
									this.xmlDecl = curr.value;
								}else{
									this.docTypeDecl = curr.value;
								}
							}
						}
					}
					++i;
				}
			}else{
				while (i<max){
					curr = tags[i];
					if (curr.type == 1){
						if (curr.value == "/"+treePtr.nodeName){
							treePtr = treePtr.parentNode;
						}else{
							treePtr.appendChild(this.createElement(curr.value));
							treePtr = treePtr.lastChild;
							treePtr.attributes = curr.attrs;
							if (curr.empty){
								treePtr = treePtr.parentNode;
							}
						}
					}else{
						if (curr.type == 3 || curr.type == 6){
							treePtr.appendChild(this.createTextNode(curr.value));
						}else{
							if (curr.type == 4){
								this.xmlDecl = curr.value;
							}else{
								this.docTypeDecl = curr.value;
							}
						}
					}
					++i;
				}
			}
		}
	}
}
