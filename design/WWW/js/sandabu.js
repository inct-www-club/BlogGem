resize_image();

window.resize = resize_image();

//サイズの表示
function resize_image() {
    var thu = $("div.thuimg");
    var width = thu.width();
    thu.css("height", width*0.8);
}
