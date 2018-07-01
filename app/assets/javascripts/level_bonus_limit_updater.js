var LevelBonusLimitUpdater = function() {
    var timerData = [];

    var start = function(bonusNum) {
        updateCountdown(bonusNum);
        timerData[bonusNum].intervalId = setInterval(function () { updateCountdown(bonusNum); }, 1000);

        setTimeout(function () { stop(bonusNum)}, timerData[bonusNum].countdownValue * 1000 + 1000);
    }
        ,stop = function(bonusNum) {
        clearInterval(timerData[bonusNum].intervalId);
        timerData[bonusNum].countdownValue = 0;

        loadBonus(bonusNum);
    }
        ,updateCountdown = function(bonusNum) {
        var minutes = timerData[bonusNum].countdownValue / 60
            ,seconds = 0;

        if ( minutes > 0 && Math.floor(minutes) !== minutes ) {
            minutes = Math.floor(minutes);
            seconds = timerData[bonusNum].countdownValue % 60;
        } else {
            seconds = timerData[bonusNum].countdownValue % 60;
        }

        timerData[bonusNum].countdownTimerText.text(minutes + ' хв ' + seconds + ' сек');
        timerData[bonusNum].countdownValue--;
    }
        ,hideCountdownContainer = function(bonusNum) {
        timerData[bonusNum].countdownContainer.hide();
    }
        ,showLoadIndicator = function(bonusNum) {
        timerData[bonusNum].loadingIndicator.show();
    }
        ,hideLoadIndicator = function(bonusNum) {
        timerData[bonusNum].loadingIndicator.hide();
    }
        ,appendBonus = function(bonus_num, bonus_name) {
        $('bonus-' + bonus_num).html('<p class="bonus"><b>' + bonus_name + ' не виконано</b></p>');
    }
        ,loadBonus = function(bonusNum) {
        hideCountdownContainer(bonusNum);
        showLoadIndicator(bonusNum);

        $.ajax({
            url: '/play/' + timerData[bonusNum].gameId + '/bonus_miss',
            method: 'POST',
            data: {team_id: timerData[bonusNum].teamId, level_id: timerData[bonusNum].levelId, bonus_id: timerData[bonusNum].bonusId},
            dataType: 'json',
            success: function(data) {
                hideLoadIndicator(bonusNum);
                appendBonus(data.bonus_num, data.bonus_name);
            }
        });
    };

    return {
        setup: function(config) {
            $(document).ready(function() {
                timerData[config.bonusNum] =
                    {
                        gameId: config.gameId,
                        teamId: config.teamId,
                        bonusId: config.bonusId,
                        bonusNum: config.bonusNum,
                        levelId: config.levelId,
                        countdownContainer: $('#LevelBonusLimitCountdownContainer' + config.bonusId),
                        countdownTimerText: $('#LevelBonusLimitCountdownTimerText' + config.bonusId),
                        loadingIndicator: $('#LevelBonusLimitCountdownLoadIndicator' + config.bonusId),
                        countdownValue: config.initialCountdownValue
                    };
                start(config.bonusId);
            });
        }
    };
}();