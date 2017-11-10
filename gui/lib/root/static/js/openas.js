/* ##########################################
## JS for AS Comunication Gateway
## (c) 2009 underground_8 secure computing 
##### @author: vo@underground8.com 
##### @last_changed: 2009-04-2
############################################# */
/* -- login only works when javascript is enabled -- */
function removeAttributes(){
	if(document.getElementById('login_form')){
		document.getElementById('username').removeAttribute('disabled', 0);
		document.getElementById('password').removeAttribute('disabled', 0);
		document.getElementById('submit').removeAttribute('disabled', 0);
	}
}
/* -- externally defined variables -- */
new_ts = 0;
new_tz = 0;
var reminder_counter = 1;
var current_reminder = 0;

/* -- displays the current SYSTEM time and date -- */
function start_clock(){
    if (new_ts != 0){
        timestamp = new_ts;
        timezone = new_tz;
        new_ts = 0;
        new_tz = 0;
    }
	
	current_time = new Date(timestamp);

	seconds = zerosprint(current_time.getSeconds());
	minutes = zerosprint(current_time.getMinutes());
	hours = zerosprint(current_time.getHours());
	day = zerosprint(current_time.getDate());
	month = zerosprint(current_time.getMonth()+1);
	if(current_time.getYear() < 2000) {
		year = current_time.getYear()+1900;
	}else{
		year = current_time.getYear();
	}

	time = hours + ':' + minutes + ':' + seconds;
	date = year + '-' + month + '-' + day;

	document.getElementById('clock').innerHTML = time + ' (' + timezone + ')' + ' | ' + date;

    timestamp = timestamp + 1000; // plus one second ()is in miliseconds because js uses miliseconds, not seconds
	setTimeout('start_clock()', 1000);
}

/* -- [helper function] for update_clock(): set a 0 in front of one digit numbers -- */
function zerosprint(num) { return (num < 10) ? "0" + num : num; };

/* -- change the Clock that is always displayed in the layout via timesettings -- */
function set_new_timestamp(){
    var arr = (document.getElementById('new_timestamp').innerHTML).split(",");
    new_ts = new Date(arr[0],arr[1]-1,arr[2],arr[3],arr[4],arr[5]).getTime(); 
    new_tz = document.getElementById('new_timezone').innerHTML;
}

/* -- necessary to make navigation drop down working in IE6 -- */
sfHover = function() {
	var sfEls = document.getElementById("main_menu").getElementsByTagName("LI");
	for (var i=0; i<sfEls.length; i++) {
		sfEls[i].onmouseover=function() {
			this.className+=" hover";
		}
		sfEls[i].onmouseout=function() {
			this.className=this.className.replace(new RegExp(" hover\\b"), "");
		}
	}
}
if (window.attachEvent) window.attachEvent("onload", sfHover);

/* -- toggle widgets in the sidebar of the dashboard -- */
function toggle_widget(container_id, link){
	Effect.toggle(container_id, 'blind');
	changeClass(link, 'toggle_up', 'toggle_down');
}

/* -- chance the class name of an Element -- */
function changeClass(element, class1, class2){
    document.getElementById(element).className = (document.getElementById(element).className == class1)?class2:class1;
    //element.className = (element.className == class1)?class2:class1;
}

/* -- invert all selected status from checkboxes in this form -- */
function invert_selection(form_id){
	var the_form = document.getElementById(form_id);
	for(z=0; z<the_form.elements.length;z++){
		if(the_form.elements[z].type == 'checkbox'){
				the_form.elements[z].checked = 1 - the_form.elements[z].checked;
			}
	}
}

/* -- check/uncheck all checkboxes in this form -- */
function change_selection(form_id, checked_or_unchecked){
	var the_form = document.getElementById(form_id);
	for(z=0; z<the_form.elements.length;z++){
		if(the_form.elements[z].type == 'checkbox'){
			if(checked_or_unchecked == true){
				the_form.elements[z].checked = true;
			}else{
				the_form.elements[z].checked = false;
			}
		}
	}
}

/* -- show overlay and stretch it to complete page -- */
function show_overlay(){
	var arrayPageSize = this.getPageSize();
	$('overlay').setStyle({width: arrayPageSize[0] + 'px', height: arrayPageSize[1] + 'px' });
	$('overlay').appear({duration: 0.1, to: 0.9});
	$('horizon').appear({duration: 0.1, to: 1.0}); 
}

/* -- fade out overlay div on cancel of operation -- */
function fade_overlay(){
	$('overlay').fade({duration: 0.2});
	$('horizon').fade({duration: 0.2});
}

/* -- helper function to get Page Size for overlay -- */
function getPageSize(){
	var xScroll, yScroll;

	if (window.innerHeight && window.scrollMaxY) {	
		xScroll = window.innerWidth + window.scrollMaxX;
		yScroll = window.innerHeight + window.scrollMaxY;
	}else if(document.body.scrollHeight > document.body.offsetHeight){ // all but Explorer Mac
		xScroll = document.body.scrollWidth;
		yScroll = document.body.scrollHeight;
	}else{ // Explorer Mac...would also work in Explorer 6 Strict, Mozilla and Safari
		xScroll = document.body.offsetWidth;
		yScroll = document.body.offsetHeight;
	}

	var windowWidth, windowHeight;

	if (self.innerHeight) {	// all except Explorer
		if(document.documentElement.clientWidth){
			windowWidth = document.documentElement.clientWidth; 
		}else{
			windowWidth = self.innerWidth;
		}
		windowHeight = self.innerHeight;
	}else if(document.documentElement && document.documentElement.clientHeight) { // Explorer 6 Strict Mode
		windowWidth = document.documentElement.clientWidth;
		windowHeight = document.documentElement.clientHeight;
	}else if(document.body) { // other Explorers
		windowWidth = document.body.clientWidth;
		windowHeight = document.body.clientHeight;
	}	

	// for small pages with total height less then height of the viewport
	if(yScroll < windowHeight){
		pageHeight = windowHeight;
	}else{ 
		pageHeight = yScroll;
	}

	// for small pages with total width less then width of the viewport
	if(xScroll < windowWidth){	
		pageWidth = xScroll;		
	}else{
		pageWidth = windowWidth;
	}

return [pageWidth,pageHeight];
}

function reminder_slider(){
	if(reminder_counter <= number_of_reminders){
		if(reminder_counter == 1){
			current_reminder = number_of_reminders;
		}else{
			current_reminder = reminder_counter - 1;
		}
		Effect.SlideDown('reminder_'+reminder_counter, {duration: 0.3});
		Effect.SlideUp('reminder_'+current_reminder, {duration: 0.3});
		setTimeout('reminder_slider()', 3000);
		if(reminder_counter == number_of_reminders){
			reminder_counter = 1; //reset
		}else{
			reminder_counter++;
		}
	}
}

function redirect_to (dest){
    window.location = dest;
}

function redirect_on_event(){
    var url = document.getElementById('redirect_url');
    var timeout = document.getElementById('redirect_timeout');

    if (url && timeout){
        window.setTimeout (function () {redirect_to (url.innerHTML);}, timeout.innerHTML);
    }
    else if (url){
        redirect_to(url.innerHTML);
    }
}

	

/* ########################################################################### */
/* ########################################################################### */
/* ----------------------------------- OLD ----------------------------------- */
/* ########################################################################### */
/* ########################################################################### */
function toggle_help_button(setting){
    var buttonElem = document.getElementById('helpButton');
    var currentClass = buttonElem.className;
    var newclass = (setting == 0) ? 'inactive' : 'active';
    buttonElem.setAttribute('class', newclass);
    buttonElem.setAttribute('className', newclass);
    return;
}


/* -- shows statistics on frontpage and update them live -- */
function showStats(clean, tagged, spam, greylisted, blacklisted, virus, attachment){
	element_ids = new Array("passed", "tagged", "spam", "greylisted", "blacklisted", "virus", "attachment");
	mails = new Array(clean, tagged, spam, greylisted, blacklisted, virus, attachment);
	
	var all_mails = 0;
	
	for(var i = 0; i < mails.length; i++){
		all_mails += mails[i];
	}
	
	var one_percent = all_mails / 100; 
	
	for(var j = 0; j < element_ids.length; j++){
		var height = Math.round(mails[j] / one_percent);
		if(height >= 1){
			Element.setStyle(element_ids[j],{'height':height+'px'});
			var offset = (105 - height); // 105 because the Containter for the stats is 105px high
			
			Element.setStyle(element_ids[j],{'margin-top':offset+'px'});
			Element.setStyle(element_ids[j],{'visibility':'visible'});	
		}
	}
}

/* -- toggle the display of elements in any form - works great with checkboxes -- */
function toggleElements(checkboxname, divname){
    if(document.getElementById(checkboxname).checked == true){
        Element.setStyle(divname, {display: 'block'});
    }else{
        Element.setStyle(divname, {display: 'none'});
    }
}

/* -- toggles the visibility of some of the notification elements -- */
function toggleNotificationElements(srv_inut_id, smtp_srv_container){
	if(document.getElementById(srv_inut_id).value.length == 0){
		Element.setStyle(smtp_srv_container, {display: 'none'});
	}else{
		Element.setStyle(smtp_srv_container, {display: 'block'});
	}
}

/* -- Helping Function when there is more than one function that has to be loaded on window.onload -- */
function addLoadEvent(func) {
	var oldonload = window.onload;
	if (typeof window.onload != 'function') {
		window.onload = func;
	} else {
		window.onload = function() {
			oldonload();
			func();
		}
	}
}

/* -- Function to be able to call a submit via something else than a submit button and still use our fancy ajax framework -- */
function submit_remote_form(form_id) {
    if (document.getElementById(form_id).onsubmit) {
        document.getElementById(form_id).submit();
        document.getElementById(form_id).onsubmit();
    }
}
