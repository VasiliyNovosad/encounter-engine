var LevelBonusDelayUpdater = function() {
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
            bonus = '<p class="bonus"><b>' + bonus_name + '</b></p>' + bonus_task;
        }
        $('#bonus-' + bonus_num).html(bonus);
    }
    ,loadBonus = function(bonusNum) {
        hideCountdownContainer(bonusNum);
        showLoadIndicator(bonusNum);

        $.ajax({
            url: '/play/' + timerData[bonusNum].gameId + '/bonus?team_id=' + timerData[bonusNum].teamId + '&level_id=' + timerData[bonusNum].levelId + '&bonus_id=' + timerData[bonusNum].bonusId, method: 'GET', dataType: 'json',
            success: function(data) {
                hideLoadIndicator(bonusNum);
                appendBonus(data.bonus_num, data.bonus_name, data.bonus_task, data.bonus_id, data.bonus_limited, data.bonus_valid_for, timerData[data.bonus_num].gameId, timerData[data.bonus_num].teamId, timerData[data.bonus_num].levelId);
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
                        countdownContainer: $('#LevelBonusDelayCountdownContainer' + config.bonusId),
                        countdownTimerText: $('#LevelBonusDelayCountdownTimerText' + config.bonusId),
                        loadingIndicator: $('#LevelBonusDelayCountdownLoadIndicator' + config.bonusId),
                        countdownValue: config.initialCountdownValue
                    };
                start(config.bonusNum);
            });
        }
    };
}();
