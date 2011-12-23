#include ../cURL.ahk

if res := curl_global_init(){
	msgbox % "Global initialization error: " res
	exitapp
}
curl_formadd(first
            ,last
            ,"CURLFORM_COPYNAME", "uploadedfile"
            ,"CURLFORM_FILE", "C:\WINDOWS\Web\bullet.gif"
            ,"CURLFORM_END")

curl_formadd(first
            ,last
            ,"CURLFORM_COPYNAME", "submit"
            ,"CURLFORM_COPYCONTENTS", "Upload File"
            ,"CURLFORM_END")

if curl := curl_easy_init(){
    
    curl_easy_setopt(curl, "CURLOPT_VERBOSE", true)
    curl_easy_setopt(curl, "CURLOPT_DEBUGFUNCTION", RegisterCallBack("curl_Debug"))
    
    curl_easy_setopt(curl, "CURLOPT_URL", "http://imgin.it/test/uploader.php")
    curl_easy_setopt(curl, "CURLOPT_HTTPPOST", first)
    
    if res := curl_easy_perform(curl)
        msgbox % curl_easy_strerror(res)
    
    curl_easy_cleanup(curl)
    curl_formfree(first)
}
curl_global_cleanup()

gui, add, edit, w400 h600, % curl_Debug
gui, show
return

GuiClose:
GuiEscape:
    exitapp