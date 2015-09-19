/*
jQuery.Turbolinks ~ https://github.com/kossnocorp/jquery.turbolinks
jQuery plugin for drop-in fix binded events problem caused by Turbolinks

The MIT License
Copyright (c) 2012-2013 Sasha Koss & Rico Sta. Cruz
 */
(function(){var r,t;r=window.jQuery||("function"==typeof require?require("jquery"):void 0),t=r(document),r.turbo={version:"2.1.0",isReady:!1,use:function(r,o){return t.off(".turbo").on(""+r+".turbo",this.onLoad).on(""+o+".turbo",this.onFetch)},addCallback:function(o){return r.turbo.isReady&&o(r),t.on("turbo:ready",function(){return o(r)})},onLoad:function(){return r.turbo.isReady=!0,t.trigger("turbo:ready")},onFetch:function(){return r.turbo.isReady=!1},register:function(){return r(this.onLoad),r.fn.ready=this.addCallback}},r.turbo.register(),r.turbo.use("page:load","page:fetch")}).call(this);