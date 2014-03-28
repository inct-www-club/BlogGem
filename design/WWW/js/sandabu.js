resize_image();

$(window).resize( function(){
    resize_image();
});

function resize_image() {
    thu.css("height", $("div.thuimg").width() * 0.8);
}
