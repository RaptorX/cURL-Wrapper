#include ../cURL.ahk

if res := curl_global_init(){
	msgbox % "Global initialization error: " res
	exitapp
}

if curl := curl_easy_init(){
    curl_easy_setopt(curl, "CURLOPT_VERBOSE", true)
    curl_easy_setopt(curl, "CURLOPT_DEBUGFUNCTION", RegisterCallBack("curl_Debug"))
    
    curl_easy_setopt(curl, "CURLOPT_URL", "www.cmyip.com")
    
    if res := curl_easy_perform(curl)
        msgbox % curl_easy_strerror(res)
        
    curl_easy_cleanup(curl)
}
curl_global_cleanup()

Gui, add, Edit, w400 h400, % curl_Debug
Gui, show
return
