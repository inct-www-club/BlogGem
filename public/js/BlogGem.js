function add_str_at_cursor(target, str){
	var input_area = document.getElementsByName(target)[0];
    start = input_area.selectionStart;
    length = input_area.value.length;
    var after_add = input_area.value.substring(0, start);
    after_add += str + input_area.value.substring(start, length);
    input_area.value = after_add;
}

function check_form(target){
	var input_area = document.getElementsByName(target)[0];
  var alert_area = input_area.parentNode;
  alert_area.className = alert_area.className.replace(' alert alert-danger', '');
	if(input_area.value == ""){
		alert_area.className += " alert alert-danger";
		return false;
	}
	return true;
}

function check_form_dual(t1, t2){
	var return1 = check_form(t1);
	var return2 = check_form(t2);
	return return1 && return2;
}

function post_comment(){
  var name = document.getElementsByName('name')[0];
  var body = document.getElementsByName('body')[0];

  var succsess = document.getElementsByName('succsess')[0];
  var error = document.getElementsByName('error')[0];

  if (check_form_dual('name', 'body')){
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