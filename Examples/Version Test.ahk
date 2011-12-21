#include ../cURL.ahk

if res := curl_global_init(){
	msgbox % "Global initialization error: " res
	exitapp
}

ver := curl_version()
ptr := curl_version_info("CURLVERSION_NOW")

msgbox % "cURL version is: """ ver """`n"
       . "curl_version_info_data pointer is: """ ptr """"

curl_global_cleanup()
    exitapp