$('.call-to-action form').submit(function(event){

    $.post(this.action, $(this).serialize(), function(response) {
      var snippet = $(response).find('.call-to-action');
      $('.call-to-action').replaceWith(snippet);
    })

    return false;
});

$(document).on('closed', '.alert', function() {
  $('.call-to-action form').removeClass('hidden');
})