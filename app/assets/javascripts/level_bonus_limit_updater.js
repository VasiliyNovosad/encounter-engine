var LevelBonusLimitUpdater = function() {
    var timerData = [];

    var start = function(bonusId) {
        updateCountdown(bonusId);
        timerData[bonusId].intervalId = setInterval(function () { updateCountdown(bonusId); }, 1000);

        setTimeout(function () { stop(bonusId)}, timerData[bonusId].countdownValue * 1000 + 1000);
    }
        ,stop = function(bonusId) {
        clearInterval(timerData[bonusId].intervalId);
        timerData[bonusId].countdownValue = 0;

        loadBonus(bonusId);
    }
        ,updateCountdown = function(bonusId) {
            var hours = Math.floor(timerData[bonusId].countdownValue / 3600);
            var minutes = Math.floor((timerData[bonusId].countdownValue) / 60) - 60 * hours;
            var seconds = timerData[bonusId].countdownValue % 60;

            // if ( minutes > 0 && Math.floor(minutes) !== minutes ) {
            //     minutes = Math.floor(minutes);
            //     seconds = timerData[hintNum].countdownValue % 60;
            // } else {
            //     seconds = timerData[hintNum].countdownValue % 60;
            // }
            var text = '';
            if (hours > 0) text = text + hours + ' год ';
            if (minutes > 0) text = text + minutes + ' хв ';
            if (seconds > 0) text = text + seconds + ' сек';

            // timerData[bonusId].countdownTimerText.text(minutes + ' хв ' + seconds + ' сек');
            timerData[bonusId].countdownTimerText.text(text);
            timerData[bonusId].countdownValue--;
    }
        ,hideCountdownContainer = function(bonusId) {
        timerData[bonusId].countdownContainer.hide();
    }
        ,showLoadIndicator = function(bonusId) {
        timerData[bonusId].loadingIndicator.show();
    },
    hideLoadIndicator = function(bonusId) {
        timerData[bonusId].loadingIndicator.hide();
    },
    appendBonus = function(bonus_id, bonus_name) {
        $('#bonus-' + bonus_id).html('<p class="bonus-missed"><b>' + bonus_name + ' не виконано</b></p>');
    },
    loadBonus = function(bonusId) {
        hideCountdownContainer(bonusId);
        showLoadIndicator(bonusId);

        if ($('#bonus-' + bonusId).find('.bonus-limit-timer').length > 0) {
            $.ajax({
                url: '/play/' + timerData[bonusId].gameId + '/miss_bonus',
                method: 'POST',
                data: {team_id: timerData[bonusId].teamId, level_id: timerData[bonusId].levelId, bonus_id: bonusId},
                dataType: 'json',
                success: function(data) {
                    hideLoadIndicator(bonusId);
                    appendBonus(data.bonus_id, data.bonus_name);
                }
            });
        }

    };

    return {
        setup: function(config) {
            $(document).ready(function() {
                timerData[config.bonusId] =
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
