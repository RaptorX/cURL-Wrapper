#include ../cURL.ahk

if res := curl_global_init(){
	msgbox % "Global initialization error: " res
	exitapp
}

if curl := curl_easy_init(){
    POST = test testing
    POSTE:=curl_easy_escape(curl, POST)    
    curl_easy_unescape(curl, POSTE)    
    ; curl_easy_setopt(curl, "CURLOPT_URL", "www.paste2.org/new-paste")
    ; curl_easy_setopt(curl, "CURLOPT_POST", true)
    ; curl_easy_setopt(curl, "CURLOPT_POSTFIELDS", POST)
	; curl_easy_setopt(curl, "CURLOPT_POSTFIELDSIZE", strlen(POST))
    ; curl_easy_setopt(curl, "CURLOPT_WRITEDATA", hFile:=curl_CreateFile(a_desktop "\info.txt"))
    ; curl_easy_setopt(curl, "CURLOPT_WRITEFUNCTION", RegisterCallBack("curl_WriteFile"))
    ; curl_easy_perform(curl)
    ; curl_easy_cleanup(curl), curl_CloseHandle(hFile)
}
curl_global_cleanup()
return