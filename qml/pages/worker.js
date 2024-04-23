WorkerScript.onMessage = function(msg) {

    var xhr2 = new XMLHttpRequest;
    xhr2.open("GET", msg.loadmore, false);


    xhr2.onreadystatechange = function() {
        if (xhr2.readyState === XMLHttpRequest.DONE) {

            var mesg = {
                'data': xhr2.responseText,
                'last': msg.last
            }
            WorkerScript.sendMessage(mesg);
        }
    }
    xhr2.send();

}

