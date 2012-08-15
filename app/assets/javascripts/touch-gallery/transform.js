/*!
 * NETEYE Transform & Transition Plugin
 *
 * Copyright (c) 2010 NETEYE GmbH
 * Licensed under the MIT license
 *
 * Author: Felix Gnass [fgnass at neteye dot de]
 * Version: @{VERSION}
 */
(function($) {
	
	// ==========================================================================================
	// Private functions
	// ==========================================================================================
	
	var props = (function() {
	
		var prefixes = ['Webkit', 'Moz', 'O'];
		
		var style = document.createElement('div').style;
			  
		function findProp(name) {
			var result = '';
			if (style[name] !== undefined) {
				return name;
			}
			$.each(prefixes, function() {
				var p = this + name.charAt(0).toUpperCase() + name.substring(1);
				if (style[p] !== undefined) {
					result = p;
					return false;
				}
			});
			return result;
		}
		
		var result = {};
		$.each(['transitionDuration', 'transitionProperty', 'transform', 'transformOrigin'], function() {
			result[this] = findProp(this);
		});
		return result;
		
	})();
	
	var supports3d = (function() {
		var s = document.createElement('div').style;
		try {
			s[props.transform] = 'translate3d(0,0,0)';
			return s[props.transform].length > 0;
		}
		catch (ex) {
			return false;
		}
	})();
	
	
	function transform(el, commands) {
		var t = el.data('transform');
		if (!t) {
			t = new Transformation();
			el.data('transform', t);
		}
		if (commands !== undefined) {
			if (commands === false || commands.reset) {
				t.reset();
			}
			else {
				t.exec(commands);
			}
		}
		return t;
	}
	
	/**
	 * Class that keeps track of numeric values and converts them into a string representation
	 * that can be used as value for the -webkit-transform property. TransformFunctions are used
	 * internally by the Transformation class.
	 *
	 * // Example:
	 *
	 * var t = new TransformFunction('translate3d({x}px,{y}px,{z}px)', {x:0, y:0, z:0});
	 * t.x = 23;
	 * console.assert(t.format() == 'translate3d(23px,0px,0px)')
	 */
	function TransformFunction(pattern, defaults) {
		function fillIn(pattern, data) {
			return pattern.replace(/\{(\w+)\}/g, function(s, p1) { return data[p1]; });
		}
		this.reset = function() {
			$.extend(this, defaults);
		};
		this.format = function() {
			return fillIn(pattern, this);
		};
		this.reset();
	}
	
	/**
	 * Class that encapsulates the state of multiple TransformFunctions. The state can be modified
	 * using commands and converted into a string representation that can be used as CSS value.
	 * The class is used internally by the transform plugin.
	 */
	function Transformation() {
		var fn = {
			translate: new TransformFunction('translate({x}px,{y}px)', {x:0, y:0}),
			scale: new TransformFunction('scale({x},{y})', {x:1, y:1}),
			rotate: new TransformFunction('rotate({deg}deg)', {deg:0})
		};
		
		if (supports3d) {
			// Use 3D transforms for better performance
			fn.translate = new TransformFunction('translate3d({x}px,{y}px,0px)', {x:0, y:0});
			fn.scale = new TransformFunction('scale3d({x},{y},1)', {x:1, y:1});
		}	
		
		var commands = {
			rotate: function(deg) {
				fn.rotate.deg = deg;
			},
			rotateBy: function(deg) {
				fn.rotate.deg += deg;
			},
			scale: function(s) {
				if (typeof s == 'number') {
					s = {x: s, y: s};
				}
				fn.scale.x = s.x;
				fn.scale.y = s.y;
			},
			scaleBy: function(s) {
				if (typeof s == 'number') {
					s = {x: s, y: s};
				}
				fn.scale.x *= s.x;
				fn.scale.y *= s.y;
			},
			translate: function(s) {
				var t = fn.translate;
				if (!s) {
					s = {x: 0, y: 0};
				}
				t.x = (s.x !== undefined) ? parseInt(s.x, 10) : t.x;
				t.y = (s.y !== undefined) ? parseInt(s.y, 10) : t.y;
			},
			translateBy: function(s) {
				var t = fn.translate;
				t.x += parseInt(s.x, 10) || 0;
				t.y += parseInt(s.y, 10) || 0;
			}
		};
		this.fn = fn;
		this.exec = function(cmd) {
			for (var n in cmd) {
				if (commands[n]) {
					commands[n](cmd[n]);
				}
			}
		};
		this.reset = function() {
			$.each(fn, function() {
				this.reset();
			});
		};
		this.format = function() {
			var s = '';
			$.each(fn, function(k, v) {
				s += v.format() + ' ';
			});
			return s;
		};
	}
	
	// ==========================================================================================
	// Public API
	// ==========================================================================================
	
	$.fn.transform = function(opts) {
		var result = this;
		if ($.fn.transform.supported) {
			this.each(function() {
				var $this = $(this);
				var t = transform($this, opts);
				if (opts === undefined) {
					result = t.fn;
					return false;
				}
				var origin = opts && opts.origin ? opts.origin : '0 0';
				$this.css(props.transitionDuration, '0s')
					.css(props.transformOrigin, origin)
					.css(props.transform, t.format());
			});
		}
		return result;
	};
	
	$.fn.transform.supported = !!props.transform;
	
	$.fn.transition = function(css, opts) {
	
		opts = $.extend({
			delay: 0,
			duration: 0.4
		}, opts);
		
		var property = '';
		$.each(css, function(k, v) {
			property += k + ',';
		});

		this.each(function() {
			var $this = $(this);
			
			if (!$.fn.transition.supported) {
				$this.css(css);
				if (opts.onFinish) {
					$.proxy(opts.onFinish, $this)();
				}
				return;
			}
			
			var _duration = $this.css(props.transitionDuration);		
			
			function apply() {
				$this.css(props.transitionProperty, property).css(props.transitionDuration, opts.duration + 's');
				
				$this.css(css);
				if (opts.duration > 0) {
					$this.one('webkitTransitionEnd oTransitionEnd transitionend', afterCompletion);
				}
				else {
					setTimeout(afterCompletion, 1);					
				}
			}
			
			function afterCompletion() {
				$this.css(props.transitionDuration, _duration);
					
				if (opts.onFinish) {
					$.proxy(opts.onFinish, $this)();
				}
			}
			
			if (opts.delay > 0) {
				setTimeout(apply, opts.delay);
			}
			else {
				apply();
			}
		});
		return this;
	};
	
	$.fn.transition.supported = !!props.transitionProperty;
	
	$.fn.transformTransition = function(opts) {
		opts = $.extend({
			origin: '0 0',
			css: {}
		}, opts);
		var css = opts.css;
		if ($.fn.transform.supported) {
			css[props.transform] = transform(this, opts).format();
			this.css(props.transformOrigin, opts.origin);
		}
		return this.transition(css, opts);
	};
	
})(jQuery);