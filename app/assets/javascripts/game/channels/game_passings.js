$(document).ready(function() {
  var game_info = $('#main-game-container');
  App.game_passings = App.cable.subscriptions.create({
    channel: "GamePassingsChannel",
    game_passing_id: game_info.data('team-id'),
    level_id: game_info.data('level-id'),
    user_id: 0,
  }, {
    connected: function() {
      // Called when the subscription is ready for use on the server
    },

    disconnected: function() {
      // Called when the subscription has been terminated by the server
    },

    received: function(data) {
      if (data.url) {
        window.location.href = data.url;
        return;
      }

      var hint = data.hint;
      if (hint) {
        var hint_block = $('#penalty-hint-' + hint.id + ' .penalty-hint-body').get(0);
        hint_block.innerHTML = hint.text;
      }

      var answers = data.answers || [];
      for (var i = 0; i < answers.length; i++) {
        $('#entered-codes').prepend($('<p>' + answers[i].time + ' ' + answers[i].user + ' ' + answers[i].answer + '</p>'));
      }
      var sectors = data.sectors || [];
      for (var i = 0; i < sectors.length; i++) {
        var sector = $('#sector-' + sectors[i].position).get(0);
        if (data.level.olymp) {
          sector.innerHTML = sectors[i].value;
        } else {
          sector.innerHTML = sectors[i].name + ': ' + sectors[i].value;
        }
      }
      var bonuses = data.bonuses || [];
      for (var i = 0; i < bonuses.length; i++) {
        var elem = '<li id="bonus-' + bonuses[i].id + '">';
        elem += '<p class="bonus-answered"><strong>' + (bonuses[i].award != "" ? (bonuses[i].name + ': нагорода ' + bonuses[i].award) : (bonuses[i].name + ': виконано')) + ', код: ' + bonuses[i].value +'</strong></p>';
        if (bonuses[i].help) elem += bonuses[i].help;
        elem += '</li>';
        $('#bonus-' + bonuses[i].id).replaceWith(elem);
      }
      var needed = data.needed || 0;
      var closed = data.closed || 0;
      if (needed > 0 && closed > 0) {
        $('#codes-closed').get(0).innerHTML = 'Вірних кодів ' + closed + ' із ' + needed + ':';
      }
      var input_lock = data.input_lock || {};
      if (input_lock.input_lock) {
        $('#answer').prop('readonly', true);
        $("#code_submit").attr("disabled", true);

        var timer = Math.floor(input_lock.duration);

        var x = setInterval(function() {

          $('#entered-code').get(0).innerHTML = '<span class="wrong_code">блокування вводу: ' + --timer + ' c</span>';

          if (timer <= 0) {
            clearInterval(x);
            $('#answer').prop('readonly', false);
            $("#code_submit").attr("disabled", false);
            $('#entered-code').get(0).innerHTML = '';
          }
        }, 1000);
      } else {
        $('#answer').prop('readonly', false);
      }

      var timer_left = data.timer_left || 0;
      if (timer_left !== 0) {
        LevelCompleter.setup({
          initialCountdownValue: timer_left,
          gameId: data.game.id,
          levelId: data.level.id,
          gameType: data.game.type,
          levelNumber: data.level.position
      })
      }

    }
  });
  App.game_passings_user = App.cable.subscriptions.create({
    channel: "GamePassingsChannel",
    game_passing_id: game_info.data('team-id'),
    level_id: game_info.data('level-id'),
    user_id: game_info.data('user-id'),
  }, {
    connected: function() {
      // Called when the subscription is ready for use on the server
    },

    disconnected: function() {
      // Called when the subscription has been terminated by the server
    },

    received: function(data) {
      var input_lock = data.input_lock || {};
      if (input_lock.input_lock) {
        $('#answer').prop('readonly', true);
        $("#code_submit").attr("disabled", true);

        var timer = Math.floor(input_lock.duration);

        var x = setInterval(function() {

          $('#entered-code').get(0).innerHTML = '<span class="wrong_code">блокування вводу: ' + --timer + ' c</span>';

          if (timer <= 0) {
            clearInterval(x);
            $('#answer').prop('readonly', false);
            $("#code_submit").attr("disabled", false);
            $('#entered-code').get(0).innerHTML = '';
          }
        }, 1000);
      } else {
        $('#answer').prop('readonly', false);
      }
    }
  });
});
