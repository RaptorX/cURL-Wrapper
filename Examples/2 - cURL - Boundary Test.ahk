#include ../cURL.ahk

if res := curl_global_init(){
	msgbox % "Global initialization error: " res
	exitapp
}

b1 := curl_getdate("20111219")
b2 := curl_getdate("20111212 15:05:58 -0700")
b3 := curl_getdate("Sun, 06 Nov 1994 08:49:37 GMT")

msgbox % "Your boundaries:`n"
       . """" b1 """ for 20111219`n"
       . """" b2 """ for 20111212 15:05:58 -0700`n"
       . """" b3 """ for Sun, 25 Dec 2011 08:49:37 GMT"

curl_global_cleanup()
    exitapp