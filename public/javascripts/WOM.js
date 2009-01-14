/*************************************************************
 * Window Onload Manager (WOM) v1.0
 * Author: Justin Barlow - www.netlobo.com
 *
 * Description:
 * The WOM library of functions allows you to easily call
 * multiple javascript functions when your page loads.
 *
 * Usage:
 * Add functions to WOM using the womAdd() function. Pass the
 * name of your functions (with or without parameters) into
 * womAdd(). Then call womOn() like this:
 *     womAdd('hideDiv()');
 *     womAdd('changeBg("menuopts","#CCCCCC")');
 *     womOn();
 * WOM will now run when your page loads and run all of the
 * functions you have added using womAdd()
 *************************************************************/

/*************************************************************
 * The womOn() function will set the window.onload function to
 * be womGo() which will run all of your window.onload
 * functions.
 *************************************************************/
function womOn(){
	window.onload = womGo;
}

/*************************************************************
 * The womGo() function loops through the woms array and
 * runs each function in the array.
 *************************************************************/
function womGo(){
	for(var i = 0;i < woms.length;i++)
		eval(woms[i]);
}

/*************************************************************
 * The womAdd() function will add another function to the woms
 * array to be run when the page loads.
 *************************************************************/
function womAdd(func){
	woms[woms.length] = func;
}

/*************************************************************
 * The woms array holds all of the functions you wish to run
 * when the page loads.
 *************************************************************/
var woms = new Array();

womOn();