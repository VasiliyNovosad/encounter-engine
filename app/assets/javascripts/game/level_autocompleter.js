var LevelCompleter = function() {
    var countdownValue = 0, gameId = 0, levelId = 0, intervalId = null, gameType = 'linear', levelNumber = 0;

    var $countdownTimerText;

    var start = function(initialCountdownValue) {
        clearInterval(intervalId);
        if (initialCountdownValue < 0) {
            autocompleteLevel();
        } else {
            countdownValue = initialCountdownValue;
            updateCountdown();
            intervalId = setInterval(updateCountdown, 1000);

            setTimeout(stop, countdownValue * 1000 + 1000);
        }
    };

    var stop = function() {
        clearInterval(intervalId);
        countdownValue = 0;

        autocompleteLevel();
    };

    var updateCountdown = function() {
        var hours = Math.floor(countdownValue / 3600);
        var minutes = Math.floor((countdownValue) / 60)  - 60 * hours;
        var seconds = countdownValue % 60;

        var text = '';
        if (hours > 0) text = text + hours + ' год ';
        if (minutes > 0) text = text + minutes + ' хв ';
        if (seconds > 0) text = text + seconds + ' сек';

        $countdownTimerText.text(text);
        countdownValue--;
    };

    var autocompleteLevel = function() {
        $.ajax({
            url: '/play/' + gameId + '/autocomplete_level?level=' + levelId,
            method: 'GET',
            success: function() {
                if (gameType === 'panic') {
                    window.location = '/play/' + gameId + '?level=' + levelNumber;
                } else {
                    window.location = '/play/' + gameId;
                }
            }
        });
    };

    return {
        setup: function(config) {
            $(document).ready(function() {
                $countdownTimerText = $('#LevelCompleteCountdownTimerText');
                
                gameId = config.gameId;
                gameType = config.gameType || 'linear';
                levelId = config.levelId;
                levelNumber = config.levelNumber;
                start(config.initialCountdownValue);
            });
        }
    };
}();