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

function readyOnce() {}

function readyAgain(){
  $(".js-bet-click").click(placeBet);
}

$(document).ready(function() {
  readyOnce();
  readyAgain();
});
