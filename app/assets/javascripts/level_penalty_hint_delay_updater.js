var LevelPenaltyHintDelayUpdater = function() {
    var timerData = [];

    var start = function(hintId) {
        updateCountdown(hintId);
        timerData[hintId].intervalId = setInterval(function () { updateCountdown(hintId); }, 1000);

        setTimeout(function () { stop(hintId)}, timerData[hintId].countdownValue * 1000 + 1000);
    }
    ,stop = function(hintId) {
        clearInterval(timerData[hintId].intervalId);
        timerData[hintId].countdownValue = 0;

        loadHint(hintId);
    }
    ,updateCountdown = function(hintId) {
        var hours = Math.floor(timerData[hintId].countdownValue / 3600);
        var minutes = Math.floor((timerData[hintId].countdownValue) / 60) - 60 * hours;
        var seconds = timerData[hintId].countdownValue % 60;

        var text = '';
        if (hours > 0) text = text + hours + ' год ';
        if (minutes > 0) text = text + minutes + ' хв ';
        if (seconds > 0) text = text + seconds + ' сек';

        timerData[hintId].countdownTimerText.text(text);
        timerData[hintId].countdownValue--;
    }
    ,hideCountdownContainer = function(hintId) {
        timerData[hintId].countdownContainer.hide();
    }
    ,showLoadIndicator = function(hintId) {
        timerData[hintId].loadingIndicator.show();
    }
    ,hideLoadIndicator = function(hintId) {
        timerData[hintId].loadingIndicator.hide();
    }
    ,appendHint = function(hint_name, hint_id, hint_penalty, game_id, team_id, level_id) {
        var hint = '<fieldset>\n' +
            '        <legend>\n' +
            '          Штрафна підказка: ' + hint_name + ' (штраф ' + hint_penalty + ')\n' +
            '        </legend>\n' +
            '        <div class="penalty-hint-body">\n' +
            '            <form format="js" action="/play/' + game_id + '/penalty_hint" accept-charset="UTF-8" data-remote="true" method="post"><input name="utf8" type="hidden" value="✓">\n' +
            '              <input type="submit" name="commit" value="Взяти штрафну підказку" class="btn btn-outline-danger btn-sm" data-confirm="Ви впевнені?">\n' +
            '              <input type="hidden" name="level_id" id="level_id" value="' + level_id + '">\n' +
            '              <input type="hidden" name="hint_id" id="hint_id" value="' + hint_id + '">\n' +
            '              <input type="hidden" name="team_id" id="team_id" value="' + team_id + '">\n' +
            '</form>        </div>\n' +
            '      </fieldset>';
        $('#penalty-hint-' + hint_id).html(hint);
    }
    ,loadHint = function(hintId) {
        hideCountdownContainer(hintId);
        showLoadIndicator(hintId);

        $.ajax({
            url: '/play/' + timerData[hintId].gameId + '/penalty_hint?team_id=' + timerData[hintId].teamId + '&level_id=' + timerData[hintId].levelId + '&hint_id=' + hintId, method: 'GET', dataType: 'json',
            success: function(data) {
                hideLoadIndicator(hintId);
                appendHint(data.hint_name, data.hint_id, data.hint_penalty, timerData[data.hint_id].gameId, timerData[data.hint_id].teamId, timerData[data.hint_id].levelId);
            }
        });
    };

    return {
        setup: function(config) {
            $(document).ready(function() {
                timerData[config.hintId] =
                    {
                        gameId: config.gameId,
                        teamId: config.teamId,
                        hintId: config.hintId,
                        levelId: config.levelId,
                        countdownContainer: $('#LevelPenaltyHintDelayCountdownContainer' + config.hintId),
                        countdownTimerText: $('#LevelPenaltyHintDelayCountdownTimerText' + config.hintId),
                        loadingIndicator: $('#LevelPenaltyHintDelayCountdownLoadIndicator' + config.hintId),
                        countdownValue: config.initialCountdownValue
                    };
                start(config.hintId);
            });
        }
    };
}();
