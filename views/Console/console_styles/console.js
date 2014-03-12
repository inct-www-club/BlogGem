function add_str_at_cursor(target, str){
	var input_area = document.getElementsByName(target)[0];
    start = input_area.selectionStart;
    length = input_area.value.length;
    var after_add = input_area.value.substring(0, start);
    after_add += str + input_area.value.substring(start, length);
    input_area.value = after_add;
}

function check_form(input_area){
  var alert_area = input_area.parentNode;
  alert_area.className = alert_area.className.replace(' alert alert-danger', '');
	if(input_area.value == ''){
		alert_area.className += ' alert alert-danger';
		return false;
	}
	return true;
}

function check_email_address(input_area){
  if(check_form(input_area)){
    if(!input_area.value.match(/.+@.+\..+/)){
      var alert_area = input_area.parentNode;
      alert_area.className += ' alert alert-danger';
      return false;
    }
    else{
      return true;
    }
  }
  return false;
}

function post_comment(){
  var name = document.getElementsByName('name')[0];
  var body = document.getElementsByName('body')[0];

  var succsess = document.getElementsByName('succsess')[0];
  var error = document.getElementsByName('error')[0];

  var n = check_form(name);
  var b = check_form(body);

  if (n && b){
    $.post('./send-comment', {
      name: name.value,
      body: body.value
    }, function(){
      name.value = '';
      body.value = '';
      $(succsess).slideDown();
      $(error).slideUp();
    })
  }
  else{
    $(succsess).slideUp();
    $(error).slideDown();
  }

  return true;
}

function send_mail(){
  var name = document.getElementsByName('name')[0];
  var address = document.getElementsByName('address')[0];
  var body = document.getElementsByName('body')[0];

  var succsess = document.getElementsByName('succsess')[0];
  var error = document.getElementsByName('error')[0];

  var n = check_form(name);
  var a = check_email_address(address);
  var b = check_form(body);

  if (n && a && b){
    $.post('./send-mail', {
      name: name.value,
      address: address.value,
      body: body.value
    }, function(){
      name.value = '';
      address.value = '';
      body.value = '';
      $(succsess).slideDown();
      $(error).slideUp();
    })
  }
  else{
    $(succsess).slideUp();
    $(error).slideDown();
  }

  return true;
}

function allow_comment(button){
  $.get('./allow', {
    id: button.id,
  }, function(){
    button.className = 'btn btn-default';
    button.onClick = 'deny_comment(this)';
    button.innerHTML = '公開中';
  })
}

function deny_comment(button){
  $.get('./deny', {
    id: button.id,
  }, function(){
    button.className = 'btn btn-warning';
    button.onClick = 'allow_comment(this)';
    button.innerHTML = '承認する';
  })
}

function post_preview(form, action, blank){
  form.action = action;
  form.target = blank;
}

function grand_parent(element){
  return element.parentNode.parentNode;
}

$(function(){

  $("#update").bind("click", function(){

    // FormData オブジェクトを作成
    var fd = new FormData();

    // テキストデータおよびアップロードファイルが設定されていれば追加
    fd.append( "status", $("#status").val() );
    if ( $("#file").val() !== '' ) {
      fd.append( "file", $("#file").prop("files")[0] );
    }

    // dataにFormDataを指定する場合 processData,contentTypeをfalseにしてjQueryがdataを処理しないようにする
    var postData = {
      type : "POST",
      dataType : "text",
      data : fd,
      processData : false,
      contentType : false
    };

    var success = document.getElementById('success');

    // ajax送信
    $.ajax(
      "/console/upload", postData
    ).done(function(text){
      success.innerHTML = text;
      $("#success").slideDown();
      $("#error").slideUp();
    }).fail(function(text){
      $("#error").slideDown();
      $("#success").slideUp();
    });

  });

});
