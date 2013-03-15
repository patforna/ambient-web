$(document).on('submit', '.call-to-action form', function(event) {
  
    var callToActionBox = $(this).parent()
  
    $.post(this.action, $(this).serialize(), function(response) {
      var snippet = $($(response).find('.call-to-action')).first().html();
      callToActionBox.replaceWith(snippet);
    })

    return false;
});

$(document).on('closed', '.alert', function() {
  $('.call-to-action .prompt').removeClass('hidden');
})