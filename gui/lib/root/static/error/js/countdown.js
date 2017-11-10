var countdown = "601"; //10 minutes countdown; 

function doCount(){ 
	if (countdown > 0){ 
		countdown--; 
	}else{
		location.reload(true);
	}
	var s = countdown; 
	var m = Math.floor(s/60); 
	s = s % 60;
	
	if(s < 10) s = "0"+s;
	if(m < 10) m = "0"+m;

	if(document.getElementById('countdown')){
		document.getElementById('countdown').innerHTML = m+":"+s; 
	}
	window.setTimeout('doCount()',1000); 
}

doCount();