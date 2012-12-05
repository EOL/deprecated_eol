// VALIDATOR.JS by frequency-decoder.com

function addEvent( obj, type, fn )
{
        if (obj.addEventListener)
                obj.addEventListener( type, fn, false );
        else if (obj.attachEvent)
        {
                obj["e"+type+fn] = fn;
                obj[type+fn] = function() { obj["e"+type+fn]( window.event ); }
                obj.attachEvent( "on"+type, obj[type+fn] );
        }
}

if(!String.prototype.trim) String.prototype.trim = function() { return this.replace(/^\s*/,'').replace(/\s*$/, ''); }

/* NOTES:

   The validation rules are contained within html comments and have to be of the form:
   
   1. For Input and Textarea elements
   
   <!-- formElementId regularExp useOnBlur? requiredField? //-->
   
   e.g.
   
   <!-- user_name ^[a-zA-Z0-9\-_]{3,16}$ false true //-->
   
   Will check that the input/textarea with an id of "user_name" contains valid characters (a-zA-Z0-9-_) and is
   a valid length (between 3 and 16 characters).
   As the third parameter within the comment is "false", the onChange event is used instead of onBlur (which is
   advisable for accessibility purposes).
   As the fourth parameter is "true", the input/textarea is treated as a required field.
   
   2. For SelectLists
   
   <!-- formElementId regularExp useSelectedIndex? requiredField? //-->

   e.g.

   <!-- yourTitle [^0] true true //-->
   
   Will check that the select list with an id of "yourTitle" has a selectedIndex that is not 0.
   As the third parameter within the comment is "true", the regular expression is ran against the
   select lists selectedIndex. If the third parameter is "false", the regular expression is ran
   against the currently selected value i.e. selectList.option[selectList.selectedIndex].value
   Again, the fourth parameter tells the script that this is a required field.
   
*/

var formValidatorController;

(function() {

formValidator.isSupported = document.getElementById && document.getElementsByTagName;

function formValidator(formElem) {
        
        this.formElem           = formElem;
        this.rules              = new Array();
        this.styleLabelOnErr    = (formElem.className && formElem.className.search(/styleLabelOnErr/) != -1);
        this.invalidClass       = (formElem.className && formElem.className.search(/invalid-([a-zA-Z0-9\_\-]+)/) != -1) ? formElem.className.match(/invalid-([a-zA-Z0-9\_\-]+)/)[1] : "";
        this.warningClass       = (formElem.className && formElem.className.search(/warning-([a-zA-Z0-9\_\-]+)/) != -1) ? formElem.className.match(/warning-([a-zA-Z0-9\_\-]+)/)[1] : "";
        this.callbackFunction   = (formElem.className && formElem.className.search(/callback-([a-zA-Z0-9\_\-]+)/) != -1) ? formElem.className.match(/callback-([a-zA-Z0-9\_\-]+)/)[1] : "";
        this.validateAsErr      = false;
        
        this.init = function() {
                var nodes = new Array();
                
                // Get the INPUT(text/password/checkbox) tags
                var tempnodes = self.formElem.getElementsByTagName('input');
                for(var i = 0, tmpnode; tmpnode = tempnodes[i]; i++) {
                        if(typeof tmpnode.id != 'undefined' && tmpnode.id != "") {
                                if(tmpnode.type.toUpperCase() == 'TEXT' || tmpnode.type.toUpperCase() == 'PASSWORD') nodes.push(tmpnode);
                        }
                }
                
                // Get the TEXTAREA tags
                tempnodes = self.formElem.getElementsByTagName('textarea');
                for(var i = 0, tmpnode; tmpnode = tempnodes[i]; i++) if(typeof tmpnode.id != 'undefined' && tmpnode.id != "") nodes.push(tmpnode);

                // Get the SELECT tags
                tempnodes = self.formElem.getElementsByTagName('select');
                for(var i = 0, tmpnode; tmpnode = tempnodes[i]; i++) if(typeof tmpnode.id != 'undefined' && tmpnode.id != "") nodes.push(tmpnode);

                // Check for any validation rules associated with the INPUT/TEXTAREA/SELECT tags
                for(var i = 0, current; current = nodes[i]; i++) {
                
                        // Run through the previous siblings looking for COMMENT nodes
                        // NOTE: Internet Explorer 5.x does not add comments to the DOM
                        //       so the script will quietly fail in these browsers

                        while(current.previousSibling) {
                                current = current.previousSibling;
                                if(!(current.nodeName.toUpperCase().indexOf('TEXT') != -1 || current.nodeName.toUpperCase().indexOf('COMMENT') != -1)) { break; }

                                // Get the comment node and check if the form elements id is specified as part of the comment
                                if(current.nodeName.toUpperCase().indexOf('COMMENT') != -1 && current.nodeValue.trim().indexOf(nodes[i].id) == 0) {
                                        // Split the comment on the space character
                                        var argList = current.nodeValue.trim().split(" ");
                                        // Create validation rule only if we can create a RegExp with the second argument
                                        if(argList.length > 3 && typeof new RegExp(argList[1]) != 'undefined') self.addRule(nodes[i], argList[1], (argList[2] == "true" ? true : false), (argList[3] == "true" ? true : false));
                                }
                        }
                }
        }
        
        this.addRule = function(element, regex, use, required) {
                // Does the form element already have a rule assigned?
                for(var i = 0, elem; elem = this.rules[i]; i++) {
                        if(elem.element.id == element.id) {
                                elem.regex[elem.regex.length] = regex.trim();
                                return;
                        }
                }
                
                var obj         = new Object();
                obj.element     = element
                obj.element_id  = element.id;

                if(element.tagName.toUpperCase() == "SELECT") {
                        // Select lists can have the regExp ran against the selectedIndex or option.value
                        obj.useSelectedIndex = use;
                        obj.element.onchange = this.validateSingle;
                } else {
                        // Use onchange or onblur, it's up to you..
                        if(use) obj.element.onblur   = this.validateSingle;
                        else    obj.element.onchange = this.validateSingle;
                }
                
                // Is this a required form field?
                obj.required = required;

                obj.regex   = new Array(regex.trim());

                obj.valid   = true;
                this.rules.push(obj);
        }
        
        this.styleFields = function(which) {

                var label = null;
                if(self.styleLabelOnErr) {
                        // Get the implicit label if any (f.y.i. depreciated as from HTML4)
                        if(self.rules[which].element.parentNode.tagName.toUpperCase() == 'LABEL') {
                                label = self.rules[which].element.parentNode;
                        // No implicit label then search explicit label list
                        } else {
                                var labelList = self.formElem.getElementsByTagName('label');
                                // loop through label array attempting to match each 'for' attribute to the id of the current element
                                for(var lbl = 0; lbl < labelList.length; lbl++) {
                                        // Internet Explorer requires the htmlFor test
                                        if(labelList[lbl]['htmlFor'] && labelList[lbl]['htmlFor'] == self.rules[which].element.id) {
                                                label = labelList[lbl];
                                        // All other compliant browsers
                                        } else if(labelList[lbl].getAttribute('for') == self.rules[which].element.id) {
                                                label = labelList[lbl];
                                        }
                                }
                        }
                }
                
                if(self.rules[which].valid == false) {
                        if(!self.validateAsErr || !self.rules[which].required) {
                                var classout = self.invalidClass;
                                var classin  = self.warningClass;
                        } else {
                                var classout = self.warningClass;
                                var classin  = self.invalidClass;
                        }
                        self.rules[which].element.className = self.rules[which].element.className.replace(classout, "");
                        if(self.rules[which].element.className.search(classin) == -1) { self.rules[which].element.className += " " + classin; }

                        if(self.styleLabelOnErr && label != null) {
                                label.className = label.className.replace(classout, "");
                                if(label.className.search(classin) == -1) label.className += " " + classin;
                        }
                } else {
                        self.rules[which].element.className = self.rules[which].element.className.replace(self.invalidClass, "");
                        self.rules[which].element.className = self.rules[which].element.className.replace(self.warningClass, "");
                        if(self.styleLabelOnErr && label != null) {
                                label.className = label.className.replace(self.invalidClass, "");
                                label.className = label.className.replace(self.warningClass, "");
                        }
                }
        }
        
        this.validateSingleRule = function(which) {
                // If the element is disabled or hidden then automatically validate
                if(self.rules[which].element.disabled || self.rules[which].element.display == "none") {
                        self.rules[which].valid = true;
                        self.styleFields(which);
                        return;
                }

                self.rules[which].valid = true;
                
                // SELECTLIST
                if(self.rules[which].element.tagName.toUpperCase() == "SELECT") {
                        var tmpVal = self.rules[which].useSelectedIndex ? self.rules[which].element.selectedIndex : self.rules[which].element.options[self.rules[which].element.selectedIndex].value;
                        for(var i = 0, rule; rule = self.rules[which].regex[i]; i++) {
                                var isValid = new RegExp(rule).exec(tmpVal) == null ? false : true;
                                if(!isValid) {
                                        self.rules[which].valid = false;
                                }
                        }
                // INPUT/TEXTAREA
                } else {
                        for(var i = 0, rule; rule = self.rules[which].regex[i]; i++) {
                                var matched = self.rules[which].element.value.match(rule);
                                var isValid = ( matched && matched.length > 0 ) ? true : false;
                                // Validate if empty and not a required field
                                if(!self.rules[which].required && self.rules[which].element.value.trim() == '') isValid = true;
                                
                                if(!isValid) {
                                        self.rules[which].valid = false;
                                }
                        }
                }
                
                // Style the input and label
                self.styleFields(which);
        }
        
        // Event handler for individual input fields (activated onblur or onchange)
        this.validateSingle = function(e) {
                var i = 0;
                while(i<self.rules.length) {
                        if(this.id == self.rules[i].element.id) {
                                self.validateSingleRule(i);
                                break;
                        }
                        i++;
                }
                
                // Do the callback function
                if(self.callbackFunction != "" && self.callbackFunction in window) window[self.callbackFunction](false, self.getCallbackObject());

                return true;
        }
        
        // Creates an Object of objects for the callBack function (should one be defined)
        this.getCallbackObject = function() {
                var objbag = {};
                for(var i = 0; i < self.rules.length; i++) {
                        objbag[self.rules[i].element_id] = {
                                valid:self.rules[i].valid,
                                isRequired:self.rules[i].required,
                                id:self.rules[i].element_id,
                                regexp:self.rules[i].regex
                                };
                }

                return objbag;
        }
        
        // Event handler for the submit button
        this.validateAll = function(e) {
                self.validateAsErr = true;
                for(var i = 0; i < self.rules.length; i++) { self.validateSingleRule(i); }

                var isValid = (self.callbackFunction != "" && self.callbackFunction in window) ? window[self.callbackFunction](true, self.getCallbackObject()) : (self.isValid());

            	var error_message_div = document.getElementById('form_validation_error');
                if(!Boolean(isValid)) {
					if (error_message_div != null) {error_message_div.innerHTML = '<span class="error">Some required fields are not filled in.</span>';}
					return formValidatorController.stopEvent(e);
				}
				
				if (error_message_div != null) {error_message_div.innerHTML = '';}				
                return true;
                //return Boolean(isValid);
        }
        
        // Are all (required) form elements valid
        this.isValid = function() {
                var valid = true;
                for(var i = 0; i < self.rules.length; i++) {
                        if(!self.rules[i].valid && self.rules[i].required) { valid = false; }
                }
                return valid;
        }

        // Create self reference
        var self = this;

        self.init();
        
        // Attach onsubmit event handler to the form
        addEvent(self.formElem, "submit", self.validateAll);
}

formValidatorController = {
        validatorCollection: [],
        initiateFormValidation: function() {

                if(!formValidator.isSupported) return;

                var validator;
                var formCollection = document.getElementsByTagName('form');
                for(var i = 0, currentForm; currentForm = formCollection[i]; i++) {
                        validator = new formValidator(currentForm);
                        formValidatorController.validatorCollection.push(validator);
                }
        },
        stopEvent: function(e) {
                e || window.event;
                
                if (e.stopPropagation) {
                        e.stopPropagation();
                        e.preventDefault();
                }
                
                /*@cc_on@*/
                /*@if(@_win32)
                e.cancelBubble = true;
                e.returnValue = false;
                /*@end@*/

                return false;
        }
}

})();

addEvent(window, 'load', formValidatorController.initiateFormValidation);
