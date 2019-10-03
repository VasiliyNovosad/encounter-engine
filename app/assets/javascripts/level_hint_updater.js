var LevelHintUpdater = function() {
    var timerData = {};

    var
    start = function(hintNum) {
        updateCountdown(hintNum);
        timerData[hintNum].intervalId = setInterval(function () { updateCountdown(hintNum); }, 1000);

        setTimeout(function () { stop(hintNum)}, timerData[hintNum].countdownValue * 1000 + 1000);
    }

    ,stop = function(hintNum) {
        clearInterval(timerData[hintNum].intervalId);
        timerData[hintNum].countdownValue = 0;

        loadHint(hintNum);
    }

    ,updateCountdown = function(hintNum) {
        var hours = Math.floor(timerData[hintNum].countdownValue / 3600);
        var minutes = Math.floor((timerData[hintNum].countdownValue) / 60) - 60 * hours;
        var seconds = timerData[hintNum].countdownValue % 60;

        var text = '';
        if (hours > 0) text = text + hours + ' год ';
        if (minutes > 0) text = text + minutes + ' хв ';
        if (seconds > 0) text = text + seconds + ' сек';

        timerData[hintNum].countdownTimerText.text(text);
        timerData[hintNum].countdownValue--;
    }

    ,hideCountdownContainer = function(hintNum) {
        timerData[hintNum].countdownContainer.hide();
    }

    ,showLoadIndicator = function(hintNum) {
        timerData[hintNum].loadingIndicator.show();
    }

    ,hideLoadIndicator = function(hintNum) {
        timerData[hintNum].loadingIndicator.hide();
    }

    ,appendHint = function(hint_num, hint_text, hint_count, hint_id) {
        var hint_block = '<fieldset>\n' +
            '        <legend>\n' +
            '          Підказка ' + hint_num + ' із ' + hint_count + '\n' +
            '        </legend>\n' +
            '        ' + hint_text + '\n' +
            '      </fieldset>';
        $('#hint-' + hint_id).html(hint_block);
    }

    ,loadHint = function(hintNum) {
        hideCountdownContainer(hintNum);
        showLoadIndicator(hintNum);

        $.ajax({
            url: '/play/' + timerData[hintNum].gameId + '/tip?team_id=' + timerData[hintNum].teamId + '&level_id=' + timerData[hintNum].levelId + '&hint=' + timerData[hintNum].hintId, method: 'GET', dataType: 'json',
            success: function(data) {
                hideLoadIndicator(hintNum);

                appendHint(data.hint_num, data.hint_text, data.hint_count, data.hint_id);
            }
        });
    };

    return {
        setup: function(config) {
            $(document).ready(function() {
                timerData[config.hintNum] =
                    {
                        gameId: config.gameId,
                        teamId: config.teamId,
                        hintId: config.hintId,
                        levelId: config.levelId,
                        countdownContainer: $('#LevelHintCountdownContainer' + config.hintId),
                        countdownTimerText: $('#LevelHintCountdownTimerText' + config.hintId),
                        loadingIndicator: $('#LevelHintCountdownLoadIndicator' + config.hintId),
                        countdownValue: config.initialCountdownValue
                    };
                start(config.hintNum);
            });
        }
    };
}();
