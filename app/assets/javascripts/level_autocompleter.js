var LevelCompleter = function() {
    var countdownValue = 0 ,gameId = 0, levelId = 0, intervalId = null;

    var $countdownContainer, $countdownTimerText;

    var start = function(initialCountdownValue) {
        countdownValue = initialCountdownValue;

        updateCountdown();
        intervalId = setInterval(updateCountdown, 1000);

        setTimeout(stop, countdownValue * 1000 + 1000);
    };

    var stop = function() {
        clearInterval(intervalId);
        countdownValue = 0;

        autocompleteLevel();
    };

    var updateCountdown = function() {
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
    };

    var autocompleteLevel = function() {
        $.ajax({
            url: '/play/' + gameId + '/autocomplete_level?level=' + levelId, method: 'GET',
            success: function() {
                window.location.reload();
            }
        });
    };

    return {
        setup: function(config) {
            $(document).ready(function() {
                $countdownContainer = $('#LevelCompleteCountdownContainer');
                $countdownTimerText = $('#LevelCompleteCountdownTimerText');
                
                gameId = config.gameId;
                levelId = config.levelId;
                start(config.initialCountdownValue);
            });
        }
    };
}();