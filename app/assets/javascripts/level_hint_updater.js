var LevelHintUpdater = function() {
    var timerData = [];
    // var
    // countdownValue = 0
    // ,gameId = 0
    // ,teamId = 0
    // ,hintId = 0
    // ,intervalId = null;
    //
    var hintsContainer;
    // ,countdownContainer
    // ,countdownTimerText
    // ,loadingIndicator;

    var
    start = function(hintNum) {
        updateCountdown(hintNum);
        timerData[hintNum].intervalId = setInterval(function () { updateCountdown(hintNum); }, 1000);

        setTimeout(function () { stop(hintNum)}, timerData[hintNum].countdownValue * 1000 + 1000);
    }

    ,stop = function(hintNum) {
        clearInterval(timerData[hintNum].intervalId);
        timerData[hintNum].countdownValue = 0;

        // loadHint(hintNum);
        window.location = '/play/' + timerData[hintNum].gameId;
    }

    ,updateCountdown = function(hintNum) {
        var minutes = timerData[hintNum].countdownValue / 60
        ,seconds = 0;

        if ( minutes > 0 && Math.floor(minutes) != minutes ) {
            minutes = Math.floor(minutes);
            seconds = timerData[hintNum].countdownValue % 60;
        } else {
            seconds = timerData[hintNum].countdownValue % 60;
        }

        timerData[hintNum].countdownTimerText.text(minutes + ' хв ' + seconds + ' сек');
        timerData[hintNum].countdownValue--;
    }

    ,showCountdownContainer = function(hintNum) {
        timerData[hintNum].countdownContainer.show();
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

    ,appendHint = function(hint_num, hint_text, hint_count) {
        hintsContainer.append('<fieldset><legend>Підказка ' + hint_num + ' із ' + hint_count + '</legend>' + hint_text + '</br></fieldset>');
    }

    ,loadHint = function(hintNum) {
        hideCountdownContainer(hintNum);
        showLoadIndicator(hintNum);

        $.ajax({
            url: '/play/' + timerData[hintNum].gameId + '/tip?team_id=' + timerData[hintNum].teamId, method: 'GET', dataType: 'json',
            success: function(data) {
                hideLoadIndicator(hintNum);
                //showCountdownContainer(hintNum);

                appendHint(data.hint_num, data.hint_text, data.hint_count);

                // if ( !data.next_available_in ) {
                //     timerData[hintNum].countdownContainer.text('Підказок більше не буде');
                // } else {
                //     start(data.next_available_in);
                // }
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
                        countdownContainer: $('#LevelHintCountdownContainer' + config.hintId),
                        countdownTimerText: $('#LevelHintCountdownTimerText' + config.hintId),
                        loadingIndicator: $('#LevelHintCountdownLoadIndicator' + config.hintId),
                        countdownValue: config.initialCountdownValue
                    };
                hintsContainer = $('#LevelHintsContainer');
                start(config.hintNum);
            });
        }
    };
}();
