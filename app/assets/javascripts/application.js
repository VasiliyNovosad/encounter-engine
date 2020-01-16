// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery-ui/widgets/sortable
//= require jquery-ui/widgets/mouse
//= require jquery.ui.touch-punch
//= require jquery_ujs
//= require tinymce-jquery
//= require datetimepicker
//= require cocoon
//= require_tree .

function set_time_form(seconds_time, form_selector) {
    if (seconds_time >= 0) {
        var minutes = Math.trunc(seconds_time / 60);
        var seconds = seconds_time % 60;
        var hours = Math.trunc(minutes / 60);
        minutes = minutes % 60;
        $(form_selector + ' .time-hours').val(hours);
        $(form_selector + ' .time-minutes').val(minutes);
        $(form_selector + ' .time-seconds').val(seconds);
    }
}

function set_field_time(element_selector, form_selector, sign) {
    $(element_selector).val( sign * (
        parseInt($(form_selector + ' .time-hours').val()) * 3600 +
        parseInt($(form_selector + ' .time-minutes').val()) * 60 +
        parseInt($(form_selector + ' .time-seconds').val()))
    );
}