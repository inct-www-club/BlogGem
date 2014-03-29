resize_image();

$(window).resize( function(){
    resize_image();
});

function resize_image() {
    var thu = $('div.thuimg')
    thu.css('height', thu.width() * 0.8);
}
