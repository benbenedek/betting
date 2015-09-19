$(document).on('page:load',
     function(){
          $("a#fixture_ajax_trigger").bind("ajax:success",
                   function(evt, data, status, xhr){
                        //this assumes the action returns an HTML snippet
                        $("div#fixture").html(data);
           });
});
