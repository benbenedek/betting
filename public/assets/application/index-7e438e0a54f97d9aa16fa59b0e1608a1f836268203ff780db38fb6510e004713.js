(function () {
  if (window.alreadyRan) {
    return;
  }

  window.alreadyRan = true;

  $(".menu-toggler").on("click", function() { $("#playnavbar").toggleClass("in") });

  function placeBet(item) {
    match_bet_id = item.currentTarget.getAttribute('match_bet_id');
    option = item.currentTarget.getAttribute('option');
    $.ajax({
      type: "POST",
      url: "/place_bet/" + match_bet_id,
      data: { prediction: option },
      success: function () {
        $('#success_for_' + match_bet_id).show().fadeOut(1200);
      }

    });
  }

  function toggleBets(item) {
    var $this = $(this);
    // $this will contain a reference to the checkbox
    if ($this.is(':checked')) {
      $(".other_user_bet").removeClass("hidden");
    } else {
      $(".other_user_bet").addClass("hidden");
    }
  }

  function togglePreviousGames() {
    var $this = $(this);
    // $this will contain a reference to the checkbox
    if ($this.is(':checked')) {
      $(".previous_games").removeClass("hidden");
    } else {
      $(".previous_games").addClass("hidden");
    }
  }

  function readyOnce() {
    $('.loader-ajax-link').bind('ajax:beforeSend', function(evt, data, status, xhr){
      NProgress.start();
    });

    $('.loader-ajax-link').bind('ajax:complete', function(evt, data, status, xhr){
      NProgress.done();
    });
  }

  function readyAgain(){
    $(".js-bet-click").click(placeBet);
    $(".show-other-bets").click(toggleBets);
    $(".show-previous-games").click(togglePreviousGames);
    $(document).on('page:fetch',   function() { NProgress.start(); });
    $(document).on('page:change',  function() { NProgress.done(); });
    $(document).on('page:restore', function() { NProgress.remove(); });
    console.log("I am here");
    $(".menu-toggler").on("click", function() {
      console.log("Clicked");
      $("#playnavbar").toggleClass("in");
    });
  }

  function setUpTimer(diffTime) {
      var interval = 1000,
        duration = moment.duration(diffTime * 1000, 'milliseconds'),
        container = $('#leftover-time');

      setInterval(function(){
          if(diffTime < 0) {
            container.text('נגמר הזמן');
            return;
          }
          duration = moment.duration(duration.asMilliseconds() - interval, 'milliseconds')
          var d = moment.duration(duration).days(),
              h = moment.duration(duration).hours(),
              m = moment.duration(duration).minutes(),
              s = moment.duration(duration).seconds(),
              str = "נותרו ";

          d = $.trim(d).length === 1 ? '0' + d : d;
          h = $.trim(h).length === 1 ? '0' + h : h;
          m = $.trim(m).length === 1 ? '0' + m : m;
          s = $.trim(s).length === 1 ? '0' + s : s;

          if (d !== '00') { str = str.concat(d + " ימים "); }
          if (h !== '00') { str = str.concat(h + " שעות "); }
          if (m !== '00') { str = str.concat(m + " דקות "); }
          if (s !== '00') { str = str.concat(s + " שניות "); }
          str = str.concat("להמר.");
          container.text(str);
          // show how many hours, minutes and seconds are left
      }, interval);
  }

  $(document).ready(function() {
    readyOnce();
    readyAgain();
    setUpTimer(document.lastBetDate);
  });
})();
