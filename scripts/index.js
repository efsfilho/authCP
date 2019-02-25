var isauth=document.createElement("input");
function auth(e) {
  var t = "IID=-1&UserOption=OK&UserID="+e.id+"&Password="+e.pass;
  var a = new XMLHttpRequest;
  a.open("POST","/hotspot/data/GetUserCheckUserChoiceData",!0);
  a.setRequestHeader("Content-type","application/x-www-form-urlencoded");
  a.onreadystatechange = function() {
    4==a.readyState&&(document.getElementById("isauth").value=JSON.parse(a.responseText).ReturnCode)
  }
  a.send(t);
}
isauth.setAttribute("type","hidden");
isauth.setAttribute("id","isauth");
isauth.setAttribute("value","");
document.body.appendChild(isauth);

