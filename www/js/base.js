function time() {
	var date = new Date;

	var hou = date.getHours();
	var min = date.getMinutes();
	var sec = date.getSeconds();

	return hou + (min < 10 ? ':0' : ':') + min + (sec < 10 ? ':0' : ':') + sec;
}



function clock() {
	document.getElementById("clock").innerHTML = time();
	setTimeout("clock();", 1000);
}



/* checking/unchecking/switching all checkboxes of
 * specified name */
function checkall(formname, checkboxname, action) {
	var form = document.forms[formname];
	var count = form.elements.length;
	var re = new RegExp(checkboxname);

	for (var i = 0; i < count; i++) {
		element = form.elements[i];
		if (element.name.match(re) && element.type == 'checkbox') {
			element.checked = action < 2 ?
				action : element.checked ? false : true;
		}
	}

}

