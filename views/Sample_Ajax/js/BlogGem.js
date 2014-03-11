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
  var name = document.getElementById('name');
  var body = document.getElementById('body');

  var success = document.getElementById('success');
  var error = document.getElementById('error');

  var n = check_form(name);
  var b = check_form(body);

  if (n && b){
    $.post('./send-comment', {
      name: name.value,
      body: body.value
    }, function(){
      name.value = '';
      body.value = '';
      $(success).slideDown();
      $(error).slideUp();
    })
  }
  else{
    $(success).slideUp();
    $(error).slideDown();
  }

  return true;
}

function send_mail(){
  var name = document.getElementById('name');
  var address = document.getElementById('address');
  var body = document.getElementById('body');

  var success = document.getElementById('success');
  var error = document.getElementById('error');

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
      $(success).slideDown();
      $(error).slideUp();
    })
  }
  else{
    $(success).slideUp();
    $(error).slideDown();
  }

  return true;
}
