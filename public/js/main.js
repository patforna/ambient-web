$(document).on('submit', '.call-to-action form', function(event) {
  
    var callToActionBox = $(this).parent()
  
    $.post(this.action, $(this).serialize(), function(response) {
      var snippet = $($(response).find('.call-to-action')).first().html();
      callToActionBox.replaceWith(snippet);
	  _gaq.push(['_trackEvent', 'action', 'signup']);
    })

    return false;
});

$(document).on('closed', '.alert', function() {
  $('.call-to-action .prompt').removeClass('hidden');
});

$(document).on('click', '.icon-facebook', function() {
  _gaq.push(['_trackEvent', 'action', 'social', 'facebook']);
});

$(document).on('click', '.icon-twitter', function() {
  _gaq.push(['_trackEvent', 'action', 'social', 'twitter']);
});

