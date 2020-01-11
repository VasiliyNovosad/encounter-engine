$(document).ready(function() {
  let game_info = $('#main-game-container');
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

      let hint = data.hint;
      if (hint) {
        let hint_block = $('#penalty-hint-' + hint.id + ' .penalty-hint-body').get(0);
        hint_block.innerHTML = hint.text;
      }

      let answers = data.answers || [];
      for (let i = 0; i < answers.length; i++) {
        $('#entered-codes').prepend($('<p>' + answers[i].time + ' ' + answers[i].user + ' ' + answers[i].answer + '</p>'));
      }
      let sectors = data.sectors || [];
      for (let i = 0; i < sectors.length; i++) {
        let sector = $('#sector-' + sectors[i].position).get(0);
        if (data.level.olymp) {
          sector.innerHTML = sectors[i].value;
        } else {
          sector.innerHTML = sectors[i].name + ': ' + sectors[i].value;
        }
      }
      let bonuses = data.bonuses || [];
      for (let i = 0; i < bonuses.length; i++) {
        let elem = '<li id="bonus-' + bonuses[i].id + '">';
        elem += '<p class="bonus-answered"><strong>' + (bonuses[i].award != "" ? (bonuses[i].name + ': нагорода ' + bonuses[i].award) : (bonuses[i].name + ': виконано')) + ', код: ' + bonuses[i].value +'</strong></p>';
        if (bonuses[i].help) elem += bonuses[i].help;
        elem += '</li>';
        $('#bonus-' + bonuses[i].id).replaceWith(elem);
      }
      let needed = data.needed || 0;
      let closed = data.closed || 0;
      if (needed > 0 && closed > 0) {
        $('#codes-closed').get(0).innerHTML = 'Вірних кодів ' + closed + ' із ' + needed + ':';
      }
      let input_lock = data.input_lock || {};
      if (input_lock.input_lock) {
        $('#answer').prop('readonly', true);
        $("#code_submit").attr("disabled", true);

        let timer = Math.floor(input_lock.duration);

        let x = setInterval(function() {

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

      let timer_left = data.timer_left || 0;
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
      let input_lock = data.input_lock || {};
      if (input_lock.input_lock) {
        $('#answer').prop('readonly', true);
        $("#code_submit").attr("disabled", true);

        let timer = Math.floor(input_lock.duration);

        let x = setInterval(function() {

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
