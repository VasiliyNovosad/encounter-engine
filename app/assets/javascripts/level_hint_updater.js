var LevelHintUpdater = function() {
    var
    countdownValue = 0
    ,gameId = 0
    ,teamId = 0
    ,intervalId = null;

    var
    $hintsContainer
    ,$countdownContainer
    ,$countdownTimerText
    ,$loadingIndicator;

    var
    start = function(initialCountdownValue) {
        countdownValue = initialCountdownValue;

        updateCountdown();
        intervalId = setInterval(updateCountdown, 1000);

        setTimeout(stop, countdownValue * 1000 + 1000);
    }

    ,stop = function() {
        clearInterval(intervalId);
        countdownValue = 0;

        loadHint();
    }

    ,updateCountdown = function() {
        var minutes = countdownValue / 60
        ,seconds = 0;

        if ( minutes > 0 && Math.floor(minutes) != minutes ) {
            minutes = Math.floor(minutes);
            seconds = countdownValue % 60;
        } else {
            seconds = countdownValue % 60;
        }

        $countdownTimerText.text(minutes + ' хв ' + seconds + ' сек');
        countdownValue--;
    }

    ,showCountdownContainer = function() {
        $countdownContainer.show();
    }

    ,hideCountdownContainer = function() {
        $countdownContainer.hide();
    }

    ,showLoadIndicator = function() {
        $loadingIndicator.show();
    }

    ,hideLoadIndicator = function() {
        $loadingIndicator.hide();
    }

    ,appendHint = function(hintNum, hintText, hintCount) {
        $hintsContainer.append('<fieldset><legend>Підказка ' + hintNum + ' із ' + hintCount + '</legend>' + hintText + '</br></fieldset>');
    }

    ,loadHint = function() {
        hideCountdownContainer();
        showLoadIndicator();

        $.ajax({
            url: '/play/' + gameId + '/tip?team_id='+teamId, method: 'GET', dataType: 'json',
            success: function(data) {
                hideLoadIndicator();
                showCountdownContainer();

                appendHint(data.hint_num, data.hint_text, data.hint_count);

                if ( !data.next_available_in ) {
                    $countdownContainer.text('Підказок більше не буде');
                } else {
                    start(data.next_available_in);
                }
            }
        });
    };

    return {
        setup: function(config) {
            $(document).ready(function() {
                $hintsContainer = $('#LevelHintsContainer');
                $countdownContainer = $('#LevelHintCountdownContainer');
                $countdownTimerText = $('#LevelHintCountdownTimerText');
                $loadingIndicator = $('#LevelHintCountdownLoadIndicator');

                gameId = config.gameId;
                teamId = config.teamId;
                start(config.initialCountdownValue);
            });
        }
    };
}();
