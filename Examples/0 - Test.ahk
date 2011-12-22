#include ../cURL.ahk

if res := curl_global_init(){
	msgbox % "Global initialization error: " res
	exitapp
}

if curl := curl_easy_init(){
    
    URL :="http://www.autohotkey.net/paste/"
    POST:="MAX_FILE_SIZE=262144"
        . "&jscheck=1"
        . "&text=with MAX_FILE_SIZE [A]"
        . "&author=RaptorX"
        . "&description=" 
        . "&submit=Paste"
    
    
    ; URL :="http://www.autohotkey.net/paste/"
    ; POST:="MAX_FILE_SIZE=262144"
        ; . "&jscheck=1"
        ; . "&text=my text"
        ; . "&author=RaptorX"
        ; . "&description=my paste" 
        ; . "&submit=Paste"
        
    curl_easy_setopt(curl, "CURLOPT_URL", URL)
    curl_easy_setopt(curl, "CURLOPT_USERAGENT", "AHK-TK")
    curl_easy_setopt(curl, "CURLOPT_POST", true)
    curl_easy_setopt(curl, "CURLOPT_POSTFIELDS", &POST)
    curl_easy_setopt(curl, "CURLOPT_VERBOSE", true)
    curl_easy_setopt(curl, "CURLOPT_DEBUGFUNCTION", RegisterCallBack("curl_Debug"))
    curl_easy_perform(curl)
    curl_easy_cleanup(curl), curl_CloseHandle(hFile)
}
curl_global_cleanup()
gui, add, edit, w800 h400, % curl_Debug
gui, show
return

GuiClose:
GuiEscape:
    exitapp