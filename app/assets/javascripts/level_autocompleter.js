var LevelCompleter = function() {
    var
    countdownValue = 0
    ,gameId = 0
    ,intervalId = null;

    var
    $countdownContainer
    ,$countdownTimerText;

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

        autocompleteLevel();
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

    ,autocompleteLevel = function() {
        $.ajax({
            url: '/play/' + gameId + '/autocomplete_level', method: 'POST',
            success: function(data) {
                return true
            }
        });
    }

    return {
        setup: function(config) {
            $(document).ready(function() {
                $countdownContainer = $('#LevelCompleteCountdownContainer');
                $countdownTimerText = $('#LevelCompleteCountdownTimerText');
                
                gameId = config.gameId;
                start(config.initialCountdownValue);
            });
        }
    };
}();