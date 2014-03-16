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

function allow_comment(button){
  var del_button = document.getElementsByName(button.name)[1]
  button.blur()
  $.ajax(
    "./allow?id="+button.name
  ).done(function(text){
    button.className = 'btn btn-default';
    button.onclick = new Function("deny_comment(this)");
    button.innerHTML = '公開中';
    $(del_button).slideUp();
  });
}

function deny_comment(button){
  var del_button = document.getElementsByName(button.name)[1]
  button.blur()
  $.ajax(
    "./deny?id="+button.name
  ).done(function(text){
    button.className = 'btn btn-warning';
    button.onclick = new Function("allow_comment(this)");
    button.innerHTML = '承認する';
    $(del_button).slideDown();
  });
}

function delete_comment(button){
  button.blur()
  var comment = document.getElementById(button.name)
  $.ajax(
    "./delete?id="+button.name
  ).done(function(text){
    $(comment).hide("nomal", function(){
      $(comment).remove();
    });
  });
}

function leave_member(button){
  button.blur()
  var target_tr = document.getElementById(button.name)

  var post_data = {
    type: "POST",
    data: { id: button.name }
  }
  $.ajax(
    "./leave", post_data
  ).done(function(text){
    $(target_tr).hide("nomal", function(){
      $(target_tr).remove();
    });
  });
}

function up_category(button){
  $target = $(button).parent();
  $target.slideUp('middle', function(){
    $target.insertBefore($target.prev());
    $target.slideDown();
  });
  button.blur();
}

function down_category(button){
  $target = $(button).parent();
  $target.slideUp('middle', function(){
    $target.insertAfter($target.next());
    $target.slideDown();
  });
  button.blur();
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
