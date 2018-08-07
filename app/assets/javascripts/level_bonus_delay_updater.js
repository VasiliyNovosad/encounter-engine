var LevelBonusDelayUpdater = function() {
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
        var minutes = timerData[bonusId].countdownValue / 60
        ,seconds = 0;

        if ( minutes > 0 && Math.floor(minutes) !== minutes ) {
            minutes = Math.floor(minutes);
            seconds = timerData[bonusId].countdownValue % 60;
        } else {
            seconds = timerData[bonusId].countdownValue % 60;
        }

        timerData[bonusId].countdownTimerText.text(minutes + ' хв ' + seconds + ' сек');
        timerData[bonusId].countdownValue--;
    }
    ,hideCountdownContainer = function(bonusId) {
        timerData[bonusId].countdownContainer.hide();
    }
    ,showLoadIndicator = function(bonusId) {
        timerData[bonusId].loadingIndicator.show();
    }
    ,hideLoadIndicator = function(bonusId) {
        timerData[bonusId].loadingIndicator.hide();
    }
    ,appendBonus = function(bonus_num, bonus_name, bonus_task, bonus_id, bonus_limited, bonus_valid_for, game_id, team_id, level_id) {
        var bonus = '';
        if (bonus_limited) {
            bonus =
                '<div id="LevelBonusLimitCountdownContainer' + bonus_id + '" class="bonus bonus-limit-timer">\n' +
                '            ' + bonus_name + ' доступний <span id="LevelBonusLimitCountdownTimerText' + bonus_id + '">3 хвилини</span>\n' +
                '          </div>\n' +
                '          <div id="LevelBonusLimitCountdownLoadIndicator' + bonus_id + '" style="display: none;">Завантаження...</div>\n' +
                '          <br>\n' +
                '          ' + bonus_task + '\n' +
                '          <script>\n' +
                '              LevelBonusLimitUpdater.setup({\n' +
                '                  initialCountdownValue: ' + bonus_valid_for + ',\n' +
                '                  gameId: ' + game_id + ',\n' +
                '                  teamId: ' + team_id + ',\n' +
                '                  bonusId: ' + bonus_id + ',\n' +
                '                  bonusNum: ' + bonus_num + ',\n' +
                '                  levelId: ' + level_id + '\n' +
                '              })\n' +
                '          </script>'
        } else {
            bonus = '<p class="bonus"><b>' + bonus_id + '</b></p>' + bonus_task;
        }
        $('#bonus-' + bonus_id).html(bonus);
    }
    ,loadBonus = function(bonusId) {
        hideCountdownContainer(bonusId);
        showLoadIndicator(bonusId);

        $.ajax({
            url: '/play/' + timerData[bonusId].gameId + '/bonus?team_id=' + timerData[bonusId].teamId + '&level_id=' + timerData[bonusId].levelId + '&bonus_id=' + bonusId, method: 'GET', dataType: 'json',
            success: function(data) {
                hideLoadIndicator(bonusId);
                appendBonus(data.bonus_num, data.bonus_name, data.bonus_task, data.bonus_id, data.bonus_limited, data.bonus_valid_for, timerData[data.bonus_id].gameId, timerData[data.bonus_id].teamId, timerData[data.bonus_id].levelId);
            }
        });
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
                        countdownContainer: $('#LevelBonusDelayCountdownContainer' + config.bonusId),
                        countdownTimerText: $('#LevelBonusDelayCountdownTimerText' + config.bonusId),
                        loadingIndicator: $('#LevelBonusDelayCountdownLoadIndicator' + config.bonusId),
                        countdownValue: config.initialCountdownValue
                    };
                start(config.bonusId);
            });
        }
    };
}();
