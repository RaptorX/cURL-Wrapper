#include ../cURL.ahk

if res := curl_global_init(){
	msgbox % "Global initialization error: " res
	exitapp
}

if curl := curl_easy_init(){
    curl_easy_setopt(curl, "CURLOPT_URL", "www.cmyip.com")
    
    if res := curl_easy_perform(curl)
        curl_easy_strerror(res)
    
    curl_easy_strerror(curl_easy_getinfo(curl, "CURLINFO_EFFECTIVE_URL", iurl))
    curl_easy_strerror(curl_easy_getinfo(curl, "CURLINFO_RESPONSE_CODE", iCode))
    curl_easy_strerror(curl_easy_getinfo(curl, "CURLINFO_CONTENT_TYPE", iType))
    
    msgbox % "Effective URL: " iUrl "`n"
           . "Response Code: " iCode "`n"
           . "Request Size: " iType "`n"
           
    curl_easy_cleanup(curl)
}
curl_global_cleanup()
return