/* ========================================================================
 * Bootstrap: alert.js v3.2.0
 * http://getbootstrap.com/javascript/#alerts
 * ========================================================================
 * Copyright 2011-2014 Twitter, Inc.
 * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
 * ======================================================================== */
+function(t){"use strict";function e(e){return this.each(function(){var a=t(this),n=a.data("bs.alert");n||a.data("bs.alert",n=new r(this)),"string"==typeof e&&n[e].call(a)})}var a='[data-dismiss="alert"]',r=function(e){t(e).on("click",a,this.close)};r.VERSION="3.2.0",r.prototype.close=function(e){function a(){s.detach().trigger("closed.bs.alert").remove()}var r=t(this),n=r.attr("data-target");n||(n=r.attr("href"),n=n&&n.replace(/.*(?=#[^\s]*$)/,""));var s=t(n);e&&e.preventDefault(),s.length||(s=r.hasClass("alert")?r:r.parent()),s.trigger(e=t.Event("close.bs.alert")),e.isDefaultPrevented()||(s.removeClass("in"),t.support.transition&&s.hasClass("fade")?s.one("bsTransitionEnd",a).emulateTransitionEnd(150):a())};var n=t.fn.alert;t.fn.alert=e,t.fn.alert.Constructor=r,t.fn.alert.noConflict=function(){return t.fn.alert=n,this},t(document).on("click.bs.alert.data-api",a,r.prototype.close)}(jQuery);