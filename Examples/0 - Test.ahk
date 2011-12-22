#include ../cURL.ahk

if res := curl_global_init(){
	msgbox % "Global initialization error: " res
	exitapp
}

if curl := curl_easy_init(){

    ; This works on Ansi & Unicode
    URL :="http://www.autohotkey.net/paste/"
    POST:="MAX_FILE_SIZE=262144"
        . "&jscheck=1"
        . "&text=" strget(curl_easy_escape(curl, "This is my nice paste!!"), "CP0")
        . "&author=RaptorX"
        . "&description=" strget(curl_easy_escape(curl, "Testing automated paste!!"), "CP0")
        . "&submit=Paste"

    ; This works only on Ansi
    ; URL := "http://www.pastebin.com/api/api_post.php"
    ; POST:= "api_dev_key=786f7529a54ee64a1959612f2aeb8596"
        ; .  "&api_option=paste"
        ; .  "&api_paste_code=" strget(curl_easy_escape(curl, "This is my nice paste!"), "CP0")
        ; .  "&api_paste_expire_date=10M"
    
    ; This works only on Ansi
    ; URL := "http://dpaste.com/"
    ; POST:= "content=" strget(curl_easy_escape(curl, "This is my nice paste!"), "CP0")
        ; .  "&language="
        ; .  "&title=" strget(curl_easy_escape(curl, "Testing automated paste!"), "CP0")
        ; .  "&poster=RaptorX"
        ; .  "&hold="

    ; This wont work at all
    ; URL := "http://www.paste2.org/new-paste"
    ; POST:= "lang=text"
        ; .  "&description=" strget(curl_easy_escape(curl, "Testing automated paste!"), "CP0")
        ; .  "&code=" strget(curl_easy_escape(curl, "This is my nice paste!"), "CP0")
        ; .  "&parent=0"
    
    curl_easy_setopt(curl, "CURLOPT_URL", URL)
    curl_easy_setopt(curl, "CURLOPT_USERAGENT", "AHK-TK")
    curl_easy_setopt(curl, "CURLOPT_POST", true)
    curl_easy_setopt(curl, "CURLOPT_POSTFIELDS", &POST)
    curl_easy_setopt(curl, "CURLOPT_POSTFIELDSIZE", strlen(POST))
    curl_easy_setopt(curl, "CURLOPT_VERBOSE", true)
    curl_easy_setopt(curl, "CURLOPT_DEBUGFUNCTION", RegisterCallBack("curl_Debug"))
    curl_easy_perform(curl)
    curl_easy_cleanup(curl)
}
curl_global_cleanup()
gui, add, edit, w800 h400, % curl_Debug
gui, show
return

GuiClose:
GuiEscape:
    exitapp