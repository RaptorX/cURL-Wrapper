#include ../cURL.ahk

if res := curl_global_init(){
	msgbox % "Global initialization error: " res
	exitapp
}

if curl := curl_easy_init(){
    curl_easy_setopt(curl, "CURLOPT_URL", "www.cmyip.com")
    curl_easy_perform(curl)
    cURL_Easy_StrError(cURL_Easy_GetInfo(curl, "CURLINFO_EFFECTIVE_URL", iurl))
    cURL_Easy_StrError(cURL_Easy_GetInfo(curl, "CURLINFO_RESPONSE_CODE", iCode))
    cURL_Easy_StrError(cURL_Easy_GetInfo(curl, "CURLINFO_CONTENT_TYPE", iType))
    
    msgbox % "Effective URL: " iUrl "`n"
           . "Response Code: " iCode "`n"
           . "Request Size: " iType "`n"
           
    curl_easy_cleanup(curl)
}
curl_global_cleanup()
return