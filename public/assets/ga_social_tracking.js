// Copyright 2011 Google Inc. All Rights Reserved.
// @see http://code.google.com/p/analytics-api-samples/source/browse/trunk/src/tracking/javascript/v5/social/ga_social_tracking.js
/**
 * @fileoverview A simple script to automatically track Facebook and Twitter
 * buttons using Google Analytics social tracking feature.
 * @author api.nickm@google.com (Nick Mihailovski)
 */
/**
 * Namespace.
 * @type {Object}.
 */
var _ga=_ga||{},_gaq=_gaq||[];_ga.trackSocial=function(e,t){_ga.trackFacebook(e,t),_ga.trackTwitter(e,t)},_ga.trackFacebook=function(e,t){var n=_ga.buildTrackerName_(t);try{FB&&FB.Event&&FB.Event.subscribe&&(FB.Event.subscribe("edge.create",function(t){_gaq.push([n+"_trackSocial","facebook","like",t,e])}),FB.Event.subscribe("edge.remove",function(t){_gaq.push([n+"_trackSocial","facebook","unlike",t,e])}),FB.Event.subscribe("message.send",function(t){_gaq.push([n+"_trackSocial","facebook","send",t,e])}))}catch(r){}},_ga.buildTrackerName_=function(e){return e?e+".":""},_ga.trackTwitter=function(e,t){var n=_ga.buildTrackerName_(t);try{twttr&&twttr.events&&twttr.events.bind&&twttr.events.bind("tweet",function(t){if(t){var r;t.target&&t.target.nodeName=="IFRAME"&&(r=_ga.extractParamFromUri_(t.target.src,"url")),_gaq.push([n+"_trackSocial","twitter","tweet",r,e])}})}catch(r){}},_ga.extractParamFromUri_=function(e,t){if(!e)return;var e=e.split("#")[0],n=e.split("?");if(n.length==1)return;var r=decodeURI(n[1]);t+="=";var i=r.split("&");for(var s=0,o;o=i[s];++s)if(o.indexOf(t)===0)return unescape(o.split("=")[1]);return};