#include ../cURL.ahk

if res := curl_global_init(){
	msgbox % "Global initialization error: " res
	exitapp
}

if curl := curl_easy_init(){
    curl_easy_setopt(curl, "CURLOPT_URL", "www.cmyip.com")
    curl_easy_setopt(curl, "CURLOPT_WRITEDATA", hFile:=curl_CreateFile(a_desktop "\cmyip.html"))
    curl_easy_setopt(curl, "CURLOPT_WRITEFUNCTION", RegisterCallBack("curl_WriteFile"))
    curl_easy_perform(curl)
    curl_easy_cleanup(curl), curl_CloseHandle(hFile)
}
curl_global_cleanup()
return