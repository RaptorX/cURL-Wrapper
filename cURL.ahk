﻿; Title: cURL Wrapper for AHK
; Requires: [AHK_L 42+]
/*
    Function: Global_Init
    Sets up the program environment that libcurl needs. Think of it as an extension of the library loader. 

    This function must be called at least once within a program (a program is all the code that shares a memory 
    space) before the program calls any other function in libcurl. The environment it sets up is constant for the 
    life of the program and is the same for every program, so multiple calls have the same effect as one call.
    
    *This function is not thread safe.* You must not call it when any other thread in the program (i.e. a thread 
    sharing the same memory) is running. This doesn't just mean no other thread that is using libcurl. Because 
    *Global_Init()* calls functions of other libraries that are similarly thread unsafe, it could conflict with 
    any other thread that uses these other libraries.
    
    See the description in libcurl(3) of global environment requirements for details of how to use this function. 
    
    See: <http://curl.haxx.se/libcurl/c/curl_global_init.html>
    
    Parameters: 
    > cURL_Global_Init([DllPath, Flags])
    
    DllPath     -   Optional location for the libcurl.dll file. 
                    If not specified it will be assumed to be on *a_scriptdir*.
    Flags       -   The flags option is a bit pattern that tells libcurl exactly what features to init, as 
                    described below. Set the desired bits by ORing the values together. 
                    In normal operation, you must specify *CURL_GLOBAL_ALL*.
                    Don't use any other value unless you are familiar with it and mean to control internal
                    operations of libcurl. 
                    Accepted Flags:
                    - *CURL_GLOBAL_SSL*: (1<<0)
                    
                    - *CURL_GLOBAL_WIN32*: (1<<1)
                    
                    - *CURL_GLOBAL_ALL*: (CURL_GLOBAL_SSL|CURL_GLOBAL_WIN32)
                    
                    - *CURL_GLOBAL_NOTHING*: 0
                    
                    - *CURL_GLOBAL_DEFAULT*: CURL_GLOBAL_ALL
    
    Returns:
    *CURLE_OK* (zero) If this function returns non-zero, something went wrong and you cannot use 
    the other curl functions.
*/
cURL_Global_Init(DllPath="", Flags="CURL_GLOBAL_DEFAULT"){

    global hCurlModule
    
    DllPath := !DllPath ? "libcurl.dll" : inStr(DllPath, "libcurl.dll") ? DllPath : DllPath "\libcurl.dll"
	if !hCurlModule:=DllCall("LoadLibrary", "Str", DllPath)
		return A_ThisFunc "> Could not load library: " DllPath
    
    ; Initialize the program environment
	return DllCall("libcurl\curl_global_init", "UInt", CURL(Flags))
}

/*
    Function: Global_Cleanup
    Releases resources acquired by <Global_Init()>.

    You should call *Global_Cleanup()* once for each call you make to <Global_Init()>, after you are done 
    using libcurl.

    *This function is not thread safe.* You must not call it when any other thread in the program 
    (i.e. a thread sharing the same memory) is running. This doesn't just mean no other thread that is using
    libcurl. Because *Global_Cleanup()* calls functions of other libraries that are similarly thread unsafe,
    it could conflict with any other thread that uses these other libraries.

    See the description in libcurl(3) of global environment requirements for details of how to use this function. 
    
    See: <http://curl.haxx.se/libcurl/c/curl_global_cleanup.html>
    
    Parameters:
    > None
    
    Returns:
    Nothing is returned by this function.
*/
cURL_Global_Cleanup(){

    global hCurlModule

    return DllCall( "FreeLibrary", "UInt", hCurlModule ), DllCall("libcurl\curl_global_cleanup")
}

/*
    Function: Version
    Returns the libcurl version string.
    
    Returns a human readable string with the version number of libcurl and some of its important components (like 
    OpenSSL version).
    
    See: <http://curl.haxx.se/libcurl/c/curl_version.html>
    
    Parameters:
    > None
    
    Returns:
    A pointer to a zero terminated string.
*/
cURL_Version(){

    return DllCall("libcurl\curl_version", "AStr")
}

/*
    Function: Version_Info
    Returns run-time libcurl version info.
    
    Returns a pointer to a filled in struct with information about various run-time features in libcurl. type 
    should be set to the version of this functionality by the time you write your program. This way, libcurl will 
    always return a proper struct that your program understands, while programs in the future might get a different 
    struct. *CURLVERSION_NOW* will be the most recent one for the library you have installed:

    > ptr := cURL_Version_Info("CURLVERSION_NOW")

    Applications should use this information to judge if things are possible to do or not, instead of using 
    compile-time checks, as dynamic/DLL libraries can be changed independent of applications.
    
    The curl_version_info_data struct looks like this
    
    (start code)    
    typedef struct {   CURLversion age;     // see description below

    // when 'age' is 0 or higher, the members below also exist:  
    const char *version;                    // human readable string
    unsigned int version_num;               // numeric representation
    const char *host;                       // human readable string  
    int features;                           // bitmask, see below
    char *ssl_version;                      // human readable string
    long ssl_version_num;                   // not used, always zero
    const char *libz_version;               // human readable string
    const char **protocols;                 // list of protocols

    // when 'age' is 1 or higher, the members below also exist:
    const char *ares;                       // human readable string
    int ares_num;                           // number

    // when 'age' is 2 or higher, the member below also exists:
    const char *libidn;                     // human readable string

    // when 'age' is 3 or higher, the members below also exist:
    int iconv_ver_num;                      // '_libiconv_version' if iconv support enabled

    const char *libssh_version;             // human readable string

    } curl_version_info_data;
    (end)
    
    age - describes what the age of this struct is. The number depends on how new the libcurl you're using is. You 
    are however guaranteed to get a struct that you have a matching struct for in the header, as you tell libcurl 
    your "age" with the vAge argument.

    version - is just an ascii string for the libcurl version.

    version_num - is a 24 bit number created like this: <8 bits major number> | <8 bits minor number> | <8 bits 
    patch number>. Version 7.9.8 is therefore returned as 0x070908.

    host - is an ascii string showing what host information that this libcurl was built for. As discovered by a 
    configure script or set by the build environment.

    features - can have none, one or more bits set, and the currently defined bits are:

                    - *CURL_VERSION_IPV6*: supports IPv6

                    - *CURL_VERSION_KERBEROS4*: supports kerberos4 (when using FTP)

                    - *CURL_VERSION_SSL*: supports SSL (HTTPS/FTPS) (Added in 7.10)

                    - *CURL_VERSION_LIBZ*: supports HTTP deflate using libz (Added in 7.10)

                    - *CURL_VERSION_NTLM*: supports HTTP NTLM (added in 7.10.6)

                    - *CURL_VERSION_GSSNEGOTIATE*: supports HTTP GSS-Negotiate (added in 7.10.6)

                    - *CURL_VERSION_DEBUG*: libcurl was built with debug capabilities (added in 7.10.6)

                    - *CURL_VERSION_CURLDEBUG*: libcurl was built with memory tracking debug capabilities. This is 
                    mainly of interest for libcurl hackers. (added in 7.19.6)

                    - *CURL_VERSION_ASYNCHDNS*: libcurl was built with support for asynchronous name lookups, which
                     allows more exact timeouts (even on Windows) and less blocking when using the multi interface.
                     (added in 7.10.7)

                    - *CURL_VERSION_SPNEGO*: libcurl was built with support for SPNEGO authentication (Simple and 
                    Protected GSS-API Negotiation Mechanism, defined in RFC 2478.) (added in 7.10.8)

                    - *CURL_VERSION_LARGEFILE*: libcurl was built with support for large files. (Added in 7.11.1)

                    - *CURL_VERSION_IDN*: libcurl was built with support for IDNA, domain names with international 
                    letters. (Added in 7.12.0)

                    - *CURL_VERSION_SSPI*: libcurl was built with support for SSPI. This is only available on 
                    Windows and makes libcurl use Windows-provided functions for NTLM authentication. It also 
                    allows libcurl to use the current user and the current user's password without the app having 
                    to pass them on. (Added in 7.13.2)

                    - *CURL_VERSION_CONV*: libcurl was built with support for character conversions, as provided by
                    the CURLOPT_CONV_* callbacks. (Added in 7.15.4)

    ssl_version - is an ASCII string for the OpenSSL version used. If libcurl has no SSL support, this is *NULL*.

    ssl_version_num - is the numerical OpenSSL version value as defined by the OpenSSL project. If libcurl has no 
    SSL support, this is 0.

    libz_version - is an ASCII string (there is no numerical version). If libcurl has no libz support, this is *NULL*.

    protocols - is a pointer to an array of char * pointers, containing the names protocols that libcurl supports (
    using lowercase letters). The protocol names are the same as would be used in URLs. The array is terminated by 
    a *NULL* entry.
    
    Returns:
    A pointer to a curl_version_info_data struct.
*/
cURL_Version_Info(vAge){
    
    return DllCall("libcurl\curl_version_info", "UInt", CURL(vAge))
}

/* not working
    Function: FormAdd
    Add a section to a multipart/formdata HTTP POST.
    
    This function is used to append sections when building a multipart/formdata HTTP POST (referred to 
    as RFC2388-style posts). Append one section at a time until you've added all the sections you want included 
    and then you pass the fpost pointer as parameter to *CURLOPT_HTTPPOST*. lpost is set after each call and 
    on repeated invokes it should be left as set to allow repeated invokes to find the end of the list faster.

    After the lpost pointer follow the real arguments.

    All  list-data will be allocated by the function itself. You must call <FormFree()> after the form post 
    has been done to free the resources.

    Using POST with HTTP 1.1 implies the use of a "Expect: 100-continue" header. You can disable this header with 
    *CURLOPT_HTTPHEADER* as usual.

    First, there are some basics you need to understand about multipart/formdata posts. Each part consists of at 
    least a NAME and a CONTENTS part. If the part is made for file upload, there are also a stored CONTENT-TYPE 
    and a FILENAME. We'll discuss in the link below, what options you use to set these properties in the parts you 
    want to add to your post: <http://curl.haxx.se/libcurl/c/curl_formadd.html>

    The options listed first are for making normal parts. The options from *CURLFORM_FILE* through 
    *CURLFORM_BUFFERLENGTH* are for file upload parts.
    
    The last parameter of each call of this function must be *CURLFORM_END*.
    
    Parameters:
    > cURL_FormAdd(fpost, lpost, params)
    
    fpost   -   Empty variable that will be filled with the info passed in params.
    lpost   -   Empty variable that is also filled automatically by libcurl.
    params  -   Actual list of parameters that will be passed to this function. Please read the link above  
                carefully and check the examples provided to get an idea of how to create multipart/formdata
                lists with this function.
    
    Returns:
    *CURLE_OK* (zero) means everything was ok, non-zero means an error occurred corresponding to a *CURL_FORMADD_**
    constant defined in <curl/curl.h>
*/
cURL_FormAdd(Byref fPost, Byref lPost, Params){
    
    `(!fpost || !lpost) ? (VarSetCapacity(fpost, 4, 0), VarSetCapacity(lpost, 4, 0))
    Loop, parse, params, `,
        mod(a_index, 2) ? Fopt%a_index%:=CURL(a_loopfield) : Fval%a_index%:=a_loopfield
    
    return DllCall("libcurl\curl_formadd"
                  ,"UInt*",fpost
                  ,"UInt*",lpost
                  ,"UInt" ,%Fopt1% ,"Str" ,Fval2
                  ,"UInt" ,%Fopt3% ,"Str" ,Fval4
                  ,"UInt" ,%Fopt5% ,"Str" ,Fval6
                  ,"UInt" ,%Fopt7% ,"Str" ,Fval8
                  ,"UInt" ,%Fopt9% ,"Str" ,Fval10, CDecl)
    
}

/*
    Function: FormFree
    Free a previously build multipart/formdata HTTP POST chain.
    
    Used to clean up data previously built/appended with <FormAdd()>. This must be called 
    when the data has been used, which typically means after <Easy_Perform()> has been called. 
    
    See: <http://curl.haxx.se/libcurl/c/curl_formfree.html>
    
    Parameters:
    cURL_FormFree(fPost)
    
    fPost   -   Variable filled with a multipart/formdata list created with <FormAdd()>
    
    Returns:
    Nothing is returned by this function.
*/
cURL_FormFree(Byref fPost){
    
    return DllCall("libcurl\curl_formfree", "UInt*", fPost, "Cdecl")
}

/*
    Function: Free
    Reclaims memory that has been obtained through a libcurl call.
    
    See: <http://curl.haxx.se/libcurl/c/curl_free.html>
    
    Parameters:
    > cURL_Free(pStr)
    
    Returns:
    Nothing is returned by this function.
*/
cURL_Free(Byref pStr){

    return DllCall("libcurl\curl_free", "UInt*", pStr, "Cdecl")
}

/*
    Function: GetDate
    Convert a date string to number of seconds since January 1, 1970.
    
    This function returns the number of seconds since January 1st 1970 in the UTC time zone, for the date and time 
    that the datestring parameter specifies. The now parameter is not used, pass a *NULL* there.

    *NOTE:* This function was rewritten for the 7.12.2 release and this documentation covers the functionality of 
    the new one. The new one is not feature-complete with the old one, but most of the formats supported by the new 
    one was supported by the old too.
    
    See: <http://curl.haxx.se/libcurl/c/curl_getdate.html>
    
    Parameters:
    > cURL_GetDate(Date)
    
    Date    -   A "date" is a string containing several items separated by whitespace. The order of the items is 
                immaterial. A date string may contain many flavors of items:

    - *Calendar Date items* Can be specified several ways. Month names can only be three-letter english 
      abbreviations, numbers can be zero-prefixed and the year may use 2 or 4 digits. Examples: 06 Nov 1994, 
      06-Nov-94 and Nov-94 6.

    - *Time of the day items* This string specifies the time on a given day. You must specify it with 6 digits 
      with two colons: HH:MM:SS. To not include the time in a date string, will make the function assume 00:00:00. 
      Example: 18:19:21.

    - *Time Zone items* Specifies international time zone. There are a few acronyms supported, but in general you 
      should instead use the specific relative time compared to UTC. Supported formats include: -1200, MST, +0100.

    - *Day of the week items* Specifies a day of the week. Days of the week may be spelled out in full 
      (using english): `Sunday', `Monday', etc or they may be abbreviated to their first three letters. This is 
      usually not info that adds anything.

    - *Pure numbers* If a decimal number of the form YYYYMMDD appears, then YYYY is read as the year, MM as the 
      month number and DD as the day of the month, for the specified calendar date.
      
    Returns:
    This function returns -1 when it fails to parse the date string. Otherwise it returns the number of seconds as 
    described.

    If the year is larger than 2037 on systems with 32 bit time_t, this function will return 0x7fffffff (since 
    that is the largest possible signed 32 bit number).

    Having a 64 bit time_t is not a guarantee that dates beyond 03:14:07 UTC, January 19, 2038 will work fine. On 
    systems with a 64 bit time_t but with a crippled mktime(), curl_getdate will return -1 in this case.
    
    Examples:
    (start code)
    Sun, 06 Nov 1994 08:49:37 GMT
    Sunday, 06-Nov-94 08:49:37 GMT
    Sun Nov  6 08:49:37 1994
    06 Nov 1994 08:49:37 GMT
    06-Nov-94 08:49:37 GMT
    Nov  6 08:49:37 1994
    06 Nov 1994 08:49:37
    06-Nov-94 08:49:37
    1994 Nov 6 08:49:37
    GMT 08:49:37 06-Nov-94 Sunday
    94 6 Nov 08:49:37
    1994 Nov 6
    06-Nov-94
    Sun Nov 6 94
    1994.Nov.6
    Sun/Nov/6/94/GMT
    Sun, 06 Nov 1994 08:49:37 CET
    06 Nov 1994 08:49:37 EST
    Sun, 12 Sep 2004 15:05:58 -0700
    Sat, 11 Sep 2004 21:32:11 +0200
    20040912 15:05:58 -0700
    20040911 +0200
    (end)

    Additional Notes:
    - This parser was written to handle date formats specified in RFC 822 (including the update in RFC 1123) using 
    time zone name or time zone delta and RFC 850 (obsoleted by RFC 1036) and ANSI C's asctime() format. 
    These formats are the only ones RFC2616 says HTTP applications may use. 
    
    - The former version of this function was built with yacc and was not only very large, it was also never quite 
    understood and it wasn't possible to build with non-GNU tools since only GNU Bison could make it thread-safe!.
    The rewrite was done for 7.12.2. The new one is much smaller and uses simpler code. 
*/
cURL_GetDate(Date){
    
    a_isunicode ? (VarSetCapacity(DateA, StrPut(Date, "CP0")), StrPut(Date, &DateA, "CP0"))
    return DllCall("libcurl\curl_getdate", "Str", a_isunicode ? DateA : Date, "UInt", 0)
}

/*
    Function: sList_Append
    Add a string to a slist.
    
    *sList_Append()* appends a specified string to a linked list of strings. The existing list should be passed as 
    the first argument while the new list is returned from this function. The specified string has been appended 
    when this function returns. *sList_Append()* copies the string.

    The list should be freed again (after usage) with <sList_Free_All()>.
    
    See: <http://curl.haxx.se/libcurl/c/curl_slist_append.html>
    
    Parameters:
    > cURL_sList_Append(pList, pStr)
    
    pList   -   Variable that will contain the list.
    Str     -   String to be appended to the list.
    
    Returns:
    A *NULL* pointer is returned if anything went wrong, otherwise the new list pointer is returned.
*/
cURL_sList_Append(Byref pList, Byref pStr){
    
    pList ? : pList:=0
    return DllCall("libcurl\curl_slist_append", "UInt*", pList, "UInt*", pStr, "Cdecl")
}

/*
    Function: sList_Free_All
    Free an entire curl_slist list.
    
    *sList_Free_All()* removes all traces of a previously built curl_slist linked list.
    
    See: <http://curl.haxx.se/libcurl/c/curl_slist_free_all.html>
    
    Parameters:
    > cURL_sList_Free_All(pList)
    pList   -   Variable that contains the list.
    
    Returns:
    Nothing is returned by this function.
*/
cURL_sList_Free_All(Byref pList){
    
    return DllCall("libcurl\curl_slist_free_all", "UInt*", pList, "Cdecl")
}

; **********************************[ File Management Functions ]***********************************

cURL_CreateFile( sFile
                ,tCreate="CREATE_NEW"
                ,tAccess="GENERIC_RW"
                ,tShare="FILE_SHARE_READ"
                ,tFlags="FILE_ATTRIBUTE_NORMAL" ){

    static st:="Create,Access,Share,Flags"
    
    Loop, Parse, st, `,
    {
        extLoopField:=a_loopfield, %extLoopField%:=0
        Loop, Parse, t%a_loopfield%, %a_tab%%a_space%, %a_tab%%a_space%
            %extLoopField% |= FILE(a_loopfield)
    }
    
    return DllCall("CreateFile"
                  ,"Uint" ,&sFile
                  ,"UInt" ,Access
                  ,"UInt" ,Share
                  ,"UInt" ,0
                  ,"UInt" ,Create
                  ,"UInt" ,Flags
                  ,"UInt" ,0)
}

cURL_ReadFile(ptr, size, nmemb, hFile){

    DllCall("ReadFile"
           ,"UInt" ,hFile
           ,"UInt" ,ptr
           ,"UInt" ,size*nmemb
           ,"UInt*",tRead
           ,"UInt" ,0)
    
    return tRead
}

cURL_WriteFile(ptr, size, nmemb, hFile){

    DllCall("WriteFile"
           ,"UInt" ,hFile
           ,"UInt" ,ptr
           ,"UInt" ,size*nmemb
           ,"UInt*",tWritten
           ,"UInt" ,0)
    
    return tWritten
}

cURL_CloseHandle(fHandle){

    return DllCall("CloseHandle"
                  ,"Uint" ,fHandle)
}

cURL_Debug(cHandle, infotype, ptr, size, void){
    
    global stdout
    /*
     * This function should be used when using the CURLOPT_VERBOSE option which sends
     * more information than the normal curl call, i personally prefer this function
     * most times when i dont need a file to write to.
     * 
     * Similarly to cURL_WriteFile, you can write your own function, make sure you register it like:
	 * curl_easy_setopt(curl, CURLOPT_DEBUGFUNCTION, registercallback("ahk_debug", "C F")) ; register function
     */
    
    if !FileExist(a_temp . "\stdout")
        hFile := cURL_CreateFile(a_temp . "\stdout", "CREATE_ALWAYS")
    cURL_WriteFile(ptr, size, 1, hFile)    ; Write file size is size*nmemb... so we use 1 <<
    cURL_CloseHandle(hFile)
    
    FileRead, stdout, %a_temp%\stdout       ; Read temporary file to stdout so we can use the var later on
    return 0
}

; Function created by DeathByNukes, http://www.autohotkey.com/forum/topic32019.html
Curl_ProgressFunction( clientp, dltotal_l, dltotal_h, dlnow_l
                      ,dlnow_h, ultotal_l, ultotal_h, ulnow_l, ulnow_h){

                      msgbox true
  VarSetCapacity(dltotal, 8, 0)
  NumPut(dltotal_l, dltotal, 0), NumPut(dltotal_h, dltotal, 4)
 
  VarSetCapacity(dlnow, 8, 0)
  NumPut(dlnow_l, dlnow, 0), NumPut(dlnow_h, dlnow, 4)
 
  KBTotal := Round((NumGet(dltotal, 0, "Double") / 1024), 2)
  KBNow := Round((NumGet(dlnow, 0, "Double") / 1024), 2)
  Percent := Round((NumGet(dlnow, 0, "Double") / NumGet(dltotal, 0, "Double") * 100), 2)
  Progress, %Percent%, %KBNow% of %KBTotal% KB (%Percent% `%)
 
  Return 0
}

; **************************************[ Private Functions ]***************************************

CURL(var, val=""){
    static
    
    ; Assigning Constants
    
    CURL_GLOBAL_SSL                   := (1<<0)
    CURL_GLOBAL_WIN32                 := (1<<1)
    CURL_GLOBAL_ALL                   := (CURL_GLOBAL_SSL|CURL_GLOBAL_WIN32)
    CURL_GLOBAL_NOTHING               := 0
    CURL_GLOBAL_DEFAULT               := CURL_GLOBAL_ALL

    CURL_ERROR_SIZE                   := 256

    ; ************[CURL_VERSION]********
    CURLVERSION_FIRST                 := 1
    CURLVERSION_SECOND                := 2
    CURLVERSION_THIRD                 := 3
    CURLVERSION_FOURTH                := 4
    CURLVERSION_NOW                   := CURLVERSION_FOURTH
    CURL_VERSION_IPV6                 := (1<<0)     ; IPv6-enabled 
    CURL_VERSION_KERBEROS4            := (1<<1)     ; Kerberos auth is supported 
    CURL_VERSION_SSL                  := (1<<2)     ; SSL options are present 
    CURL_VERSION_LIBZ                 := (1<<3)     ; Libz features are present 
    CURL_VERSION_NTLM                 := (1<<4)     ; NTLM auth is supported 
    CURL_VERSION_GSSNEGOTIATE         := (1<<5)     ; Negotiate auth support 
    CURL_VERSION_DEBUG                := (1<<6)     ; Built with debug capabilities 
    CURL_VERSION_ASYNCHDNS            := (1<<7)     ; Asynchronous dns resolves 
    CURL_VERSION_SPNEGO               := (1<<8)     ; SPNEGO auth 
    CURL_VERSION_LARGEFILE            := (1<<9)     ; Supports files bigger than 2GB 
    CURL_VERSION_IDN                  := (1<<10)    ; International Domain Names support 
    CURL_VERSION_SSPI                 := (1<<11)    ; SSPI is supported 
    CURL_VERSION_CONV                 := (1<<12)    ; Character conversions supported 
    CURL_VERSION_CURLDEBUG            := 14         ; Debug memory tracking supported 

    ; ************[CURLFORM]************
    CURLFORM_COPYNAME                 := 1
    CURLFORM_PTRNAME                  := 2
    CURLFORM_NAMELENGTH               := 3
    CURLFORM_COPYCONTENTS             := 4
    CURLFORM_PTRCONTENTS              := 5
    CURLFORM_CONTENTSLENGTH           := 6
    CURLFORM_FILECONTENT              := 7
    CURLFORM_ARRAY                    := 8
    CURLFORM_FILE                     := 10
    CURLFORM_BUFFER                   := 11
    CURLFORM_BUFFERPTR                := 12
    CURLFORM_BUFFERLENGTH             := 13
    CURLFORM_CONTENTTYPE              := 14
    CURLFORM_CONTENTHEADER            := 15
    CURLFORM_FILENAME                 := 16
    CURLFORM_END                      := 17

    ; ************[CURLOPT]*************
    CURLOPTTYPE_LONG                  := 0
    CURLOPTTYPE_OBJECTPOINT           := 10000
    CURLOPTTYPE_FUNCTIONPOINT         := 20000
    CURLOPTTYPE_OFF_T                 := 30000
    
    CURLOPT_FILE                      := 10001      ; 1   + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_URL                       := 10002      ; 2   + CURLOPTTYPE_OBJECTPOINT
    
    CURLOPT_WRITEDATA                 := CURLOPT_FILE
    CURLOPT_PORT                      := 3          ; 3   + CURLOPTTYPE_LONG
    CURLOPT_PROXY                     := 10004      ; 4   + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_USERPWD                   := 10005      ; 5   + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_PROXYUSERPWD              := 10006      ; 6   + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_RANGE                     := 10007      ; 7   + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_INFILE                    := 10009      ; 9   + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_ERRORBUFFER               := 10010      ; 10  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_WRITEFUNCTION             := 20011      ; 11  + CURLOPTTYPE_FUNCTIONPOINT
    CURLOPT_READFUNCTION              := 20012      ; 12  + CURLOPTTYPE_FUNCTIONPOINT
    CURLOPT_TIMEOUT                   := 13         ; 13  + CURLOPTTYPE_LONG
    CURLOPT_INFILESIZE                := 14         ; 14  + CURLOPTTYPE_LONG
    CURLOPT_POSTFIELDS                := 10015      ; 15  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_REFERER                   := 10016      ; 16  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_FTPPORT                   := 10017      ; 17  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_USERAGENT                 := 10018      ; 18  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_LOW_SPEED_LIMIT           := 19         ; 19  + CURLOPTTYPE_LONG
    CURLOPT_LOW_SPEED_TIME            := 20         ; 20  + CURLOPTTYPE_LONG
    CURLOPT_RESUME_FROM               := 21         ; 21  + CURLOPTTYPE_LONG
    CURLOPT_COOKIE                    := 10022      ; 22  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_HTTPHEADER                := 10023      ; 23  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_HTTPPOST                  := 10024      ; 24  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_SSLCERT                   := 10025      ; 25  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_KEYPASSWD                 := 10026      ; 26  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_CRLF                      := 27         ; 27  + CURLOPTTYPE_LONG
    CURLOPT_QUOTE                     := 10028      ; 28  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_WRITEHEADER               := 10029      ; 29  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_COOKIEFILE                := 10031      ; 31  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_SSLVERSION                := 32         ; 32  + CURLOPTTYPE_LONG
    CURLOPT_TIMECONDITION             := 33         ; 33  + CURLOPTTYPE_LONG
    CURLOPT_TIMEVALUE                 := 34         ; 34  + CURLOPTTYPE_LONG
    CURLOPT_CUSTOMREQUEST             := 10036      ; 36  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_STDERR                    := 10037      ; 37  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_POSTQUOTE                 := 10039      ; 39  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_WRITEINFO                 := 10040      ; 40  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_VERBOSE                   := 41         ; 41  + CURLOPTTYPE_LONG
    CURLOPT_HEADER                    := 42         ; 42  + CURLOPTTYPE_LONG
    CURLOPT_NOPROGRESS                := 43         ; 43  + CURLOPTTYPE_LONG
    CURLOPT_NOBODY                    := 44         ; 44  + CURLOPTTYPE_LONG
    CURLOPT_FAILONERROR               := 45         ; 45  + CURLOPTTYPE_LONG
    CURLOPT_UPLOAD                    := 46         ; 46  + CURLOPTTYPE_LONG
    CURLOPT_POST                      := 47         ; 47  + CURLOPTTYPE_LONG
    CURLOPT_DIRLISTONLY               := 48         ; 48  + CURLOPTTYPE_LONG
    CURLOPT_APPEND                    := 50         ; 50  + CURLOPTTYPE_LONG
    CURLOPT_NETRC                     := 51         ; 51  + CURLOPTTYPE_LONG
    CURLOPT_FOLLOWLOCATION            := 52         ; 52  + CURLOPTTYPE_LONG
    CURLOPT_TRANSFERTEXT              := 53         ; 53  + CURLOPTTYPE_LONG
    CURLOPT_PUT                       := 54         ; 54  + CURLOPTTYPE_LONG
    CURLOPT_PROGRESSFUNCTION          := 20056      ; 56  + CURLOPTTYPE_FUNCTIONPOINT
    CURLOPT_PROGRESSDATA              := 10057      ; 57  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_AUTOREFERER               := 58         ; 58  + CURLOPTTYPE_LONG
    CURLOPT_PROXYPORT                 := 59         ; 59  + CURLOPTTYPE_LONG
    CURLOPT_POSTFIELDSIZE             := 60         ; 60  + CURLOPTTYPE_LONG
    CURLOPT_HTTPPROXYTUNNEL           := 61         ; 61  + CURLOPTTYPE_LONG
    CURLOPT_INTERFACE                 := 10062      ; 62  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_KRBLEVEL                  := 10063      ; 63  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_SSL_VERIFYPEER            := 64         ; 64  + CURLOPTTYPE_LONG
    CURLOPT_CAINFO                    := 10065      ; 65  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_MAXREDIRS                 := 68         ; 68  + CURLOPTTYPE_LONG
    CURLOPT_FILETIME                  := 69         ; 69  + CURLOPTTYPE_LONG
    CURLOPT_TELNETOPTIONS             := 10070      ; 70  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_MAXCONNECTS               := 71         ; 71  + CURLOPTTYPE_LONG
    CURLOPT_CLOSEPOLICY               := 72         ; 72  + CURLOPTTYPE_LONG
    CURLOPT_FRESH_CONNECT             := 74         ; 74  + CURLOPTTYPE_LONG
    CURLOPT_FORBID_REUSE              := 75         ; 75  + CURLOPTTYPE_LONG
    CURLOPT_RANDOM_FILE               := 10076      ; 76  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_EGDSOCKET                 := 10077      ; 77  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_CONNECTTIMEOUT            := 78         ; 78  + CURLOPTTYPE_LONG
    CURLOPT_HEADERFUNCTION            := 20079      ; 79  + CURLOPTTYPE_FUNCTIONPOINT
    CURLOPT_HTTPGET                   := 80         ; 80  + CURLOPTTYPE_LONG
    CURLOPT_SSL_VERIFYHOST            := 81         ; 81  + CURLOPTTYPE_LONG
    CURLOPT_COOKIEJAR                 := 10082      ; 82  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_SSL_CIPHER_LIST           := 10083      ; 83  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_HTTP_VERSION              := 84         ; 84  + CURLOPTTYPE_LONG
    CURLOPT_FTP_USE_EPSV              := 85         ; 85  + CURLOPTTYPE_LONG
    CURLOPT_SSLCERTTYPE               := 10086      ; 86  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_SSLKEY                    := 10087      ; 87  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_SSLKEYTYPE                := 10088      ; 88  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_SSLENGINE                 := 10089      ; 89  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_SSLENGINE_DEFAULT         := 90         ; 90  + CURLOPTTYPE_LONG
    CURLOPT_DNS_USE_GLOBAL_CACHE      := 91         ; 91  + CURLOPTTYPE_LONG
    CURLOPT_DNS_CACHE_TIMEOUT         := 92         ; 92  + CURLOPTTYPE_LONG
    CURLOPT_PREQUOTE                  := 10093      ; 93  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_DEBUGFUNCTION             := 20094      ; 94  + CURLOPTTYPE_FUNCTIONPOINT
    CURLOPT_DEBUGDATA                 := 10095      ; 95  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_COOKIESESSION             := 96         ; 96  + CURLOPTTYPE_LONG
    CURLOPT_CAPATH                    := 10097      ; 97  + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_BUFFERSIZE                := 98         ; 98  + CURLOPTTYPE_LONG
    CURLOPT_NOSIGNAL                  := 99         ; 99  + CURLOPTTYPE_LONG
    CURLOPT_SHARE                     := 10100      ; 100 + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_PROXYTYPE                 := 101        ; 101 + CURLOPTTYPE_LONG
    CURLOPT_ENCODING                  := 10102      ; 102 + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_PRIVATE                   := 10103      ; 103 + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_HTTP200ALIASES            := 10104      ; 104 + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_UNRESTRICTED_AUTH         := 105        ; 105 + CURLOPTTYPE_LONG
    CURLOPT_FTP_USE_EPRT              := 106        ; 106 + CURLOPTTYPE_LONG
    CURLOPT_HTTPAUTH                  := 107        ; 107 + CURLOPTTYPE_LONG
    CURLOPT_SSL_CTX_FUNCTION          := 20108      ; 108 + CURLOPTTYPE_FUNCTIONPOINT
    CURLOPT_SSL_CTX_DATA              := 10109      ; 109 + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_FTP_CREATE_MISSING_DIRS   := 110        ; 110 + CURLOPTTYPE_LONG
    CURLOPT_PROXYAUTH                 := 111        ; 111 + CURLOPTTYPE_LONG
    CURLOPT_FTP_RESPONSE_TIMEOUT      := 112        ; 112 + CURLOPTTYPE_LONG
    CURLOPT_IPRESOLVE                 := 113        ; 113 + CURLOPTTYPE_LONG
    CURLOPT_MAXFILESIZE               := 114        ; 114 + CURLOPTTYPE_LONG
    CURLOPT_INFILESIZE_LARGE          := 30115      ; 115 + CURLOPTTYPE_OFF_T
    CURLOPT_RESUME_FROM_LARGE         := 30116      ; 116 + CURLOPTTYPE_OFF_T
    CURLOPT_MAXFILESIZE_LARGE         := 30117      ; 117 + CURLOPTTYPE_OFF_T
    CURLOPT_NETRC_FILE                := 10118      ; 118 + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_USE_SSL                   := 119        ; 119 + CURLOPTTYPE_LONG
    CURLOPT_POSTFIELDSIZE_LARGE       := 30120      ; 120 + CURLOPTTYPE_OFF_T
    CURLOPT_TCP_NODELAY               := 121        ; 121 + CURLOPTTYPE_LONG
    CURLOPT_FTPSSLAUTH                := 129        ; 129 + CURLOPTTYPE_LONG
    CURLOPT_IOCTLFUNCTION             := 20130      ; 130 + CURLOPTTYPE_FUNCTIONPOINT
    CURLOPT_IOCTLDATA                 := 10131      ; 131 + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_FTP_ACCOUNT               := 10134      ; 134 + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_COOKIELIST                := 10135      ; 135 + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_IGNORE_CONTENT_LENGTH     := 136        ; 136 + CURLOPTTYPE_LONG
    CURLOPT_FTP_SKIP_PASV_IP          := 137        ; 137 + CURLOPTTYPE_LONG
    CURLOPT_FTP_FILEMETHOD            := 138        ; 138 + CURLOPTTYPE_LONG
    CURLOPT_LOCALPORT                 := 139        ; 139 + CURLOPTTYPE_LONG
    CURLOPT_LOCALPORTRANGE            := 140        ; 140 + CURLOPTTYPE_LONG
    CURLOPT_CONNECT_ONLY              := 141        ; 141 + CURLOPTTYPE_LONG
    CURLOPT_CONV_FROM_NETWORK_FUNCTION:= 20142      ; 142 + CURLOPTTYPE_FUNCTIONPOINT
    CURLOPT_CONV_TO_NETWORK_FUNCTION  := 20143      ; 143 + CURLOPTTYPE_FUNCTIONPOINT
    CURLOPT_CONV_FROM_UTF8_FUNCTION   := 20144      ; 144 + CURLOPTTYPE_FUNCTIONPOINT
    CURLOPT_MAX_SEND_SPEED_LARGE      := 30145      ; 145 + CURLOPTTYPE_OFF_T
    CURLOPT_MAX_RECV_SPEED_LARGE      := 30146      ; 146 + CURLOPTTYPE_OFF_T
    CURLOPT_FTP_ALTERNATIVE_TO_USER   := 10147      ; 147 + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_SOCKOPTFUNCTION           := 20148      ; 148 + CURLOPTTYPE_FUNCTIONPOINT
    CURLOPT_SOCKOPTDATA               := 10149      ; 149 + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_SSL_SESSIONID_CACHE       := 150        ; 150 + CURLOPTTYPE_LONG
    CURLOPT_SSH_AUTH_TYPES            := 151        ; 151 + CURLOPTTYPE_LONG
    CURLOPT_SSH_PUBLIC_KEYFILE        := 10152      ; 152 + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_SSH_PRIVATE_KEYFILE       := 10153      ; 153 + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_FTP_SSL_CCC               := 154        ; 154 + CURLOPTTYPE_LONG
    CURLOPT_TIMEOUT_MS                := 155        ; 155 + CURLOPTTYPE_LONG
    CURLOPT_CONNECTTIMEOUT_MS         := 156        ; 156 + CURLOPTTYPE_LONG
    CURLOPT_HTTP_TRANSFER_DECODING    := 157        ; 157 + CURLOPTTYPE_LONG
    CURLOPT_HTTP_CONTENT_DECODING     := 158        ; 158 + CURLOPTTYPE_LONG
    CURLOPT_NEW_FILE_PERMS            := 159        ; 159 + CURLOPTTYPE_LONG
    CURLOPT_NEW_DIRECTORY_PERMS       := 160        ; 160 + CURLOPTTYPE_LONG
    CURLOPT_POST301                   := 161        ; 161 + CURLOPTTYPE_LONG
    CURLOPT_SSH_HOST_PUBLIC_KEY_MD5   := 10162      ; 162 + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_OPENSOCKETFUNCTION        := 20163      ; 163 + CURLOPTTYPE_FUNCTIONPOINT
    CURLOPT_OPENSOCKETDATA            := 10164      ; 164 + CURLOPTTYPE_OBJECTPOINT
    CURLOPT_COPYPOSTFIELDS            := 10165      ; 165 + CURLOPTTYPE_OBJECTPOINT
    
    ; ************[CURLINFO]************
    CURLINFO_STRING                   := 0x100000
    CURLINFO_LONG                     := 0x200000
    CURLINFO_DOUBLE                   := 0x300000
    CURLINFO_SLIST                    := 0x400000

    CURLINFO_EFFECTIVE_URL            := 1048577    ; CURLINFO_STRING + 1
    CURLINFO_RESPONSE_CODE            := 2097154    ; CURLINFO_LONG   + 2
    CURLINFO_TOTAL_TIME               := 3145731    ; CURLINFO_DOUBLE + 3
    CURLINFO_NAMELOOKUP_TIME          := 3145732    ; CURLINFO_DOUBLE + 4
    CURLINFO_CONNECT_TIME             := 3145733    ; CURLINFO_DOUBLE + 5
    CURLINFO_PRETRANSFER_TIME         := 3145734    ; CURLINFO_DOUBLE + 6
    CURLINFO_SIZE_UPLOAD              := 3145735    ; CURLINFO_DOUBLE + 7
    CURLINFO_SIZE_DOWNLOAD            := 3145736    ; CURLINFO_DOUBLE + 8
    CURLINFO_SPEED_DOWNLOAD           := 3145737    ; CURLINFO_DOUBLE + 9
    CURLINFO_SPEED_UPLOAD             := 3145738    ; CURLINFO_DOUBLE + 10
    CURLINFO_HEADER_SIZE              := 2097163    ; CURLINFO_LONG  + 11
    CURLINFO_REQUEST_SIZE             := 2097164    ; CURLINFO_LONG  + 12
    CURLINFO_SSL_VERIFYRESULT         := 2097165    ; CURLINFO_LONG  + 13
    CURLINFO_FILETIME                 := 2097166    ; CURLINFO_LONG  + 14
    CURLINFO_CONTENT_LENGTH_DOWNLOAD  := 3145743    ; CURLINFO_DOUBLE + 15
    CURLINFO_CONTENT_LENGTH_UPLOAD    := 3145744    ; CURLINFO_DOUBLE + 16
    CURLINFO_STARTTRANSFER_TIME       := 3145745    ; CURLINFO_DOUBLE + 17
    CURLINFO_CONTENT_TYPE             := 1048594    ; CURLINFO_STRING + 18
    CURLINFO_REDIRECT_TIME            := 3145747    ; CURLINFO_DOUBLE + 19
    CURLINFO_REDIRECT_COUNT           := 2097172    ; CURLINFO_LONG   + 20
    CURLINFO_PRIVATE                  := 1048597    ; CURLINFO_STRING + 21
    CURLINFO_HTTP_CONNECTCODE         := 2097174    ; CURLINFO_LONG   + 22
    CURLINFO_HTTPAUTH_AVAIL           := 2097175    ; CURLINFO_LONG   + 23
    CURLINFO_PROXYAUTH_AVAIL          := 2097176    ; CURLINFO_LONG   + 24
    CURLINFO_OS_ERRNO                 := 2097177    ; CURLINFO_LONG   + 25
    CURLINFO_NUM_CONNECTS             := 2097178    ; CURLINFO_LONG   + 26
    CURLINFO_SSL_ENGINES              := 4194331    ; CURLINFO_SLIST  + 27
    CURLINFO_COOKIELIST               := 4194332    ; CURLINFO_SLIST  + 28
    CURLINFO_LASTSOCKET               := 2097181    ; CURLINFO_LONG   + 29
    CURLINFO_FTP_ENTRY_PATH           := 1048606    ; CURLINFO_STRING + 30
    
    ; ************[CURLPAUSE]***********
    CURLPAUSE_RECV                    := (1<<0)
    CURLPAUSE_RECV_CONT               := (0)
    CURLPAUSE_SEND                    := (1<<2)
    CURLPAUSE_SEND_CONT               := (0)
    CURLPAUSE_ALL                     := (CURLPAUSE_RECV | CURLPAUSE_SEND)
    CURLPAUSE_CONT                    := (CURLPAUSE_RECV_CONT | CURLPAUSE_SEND_CONT)
    CURL_READFUNC_PAUSE               := 0x10000001
    CURL_WRITEFUNC_PAUSE              := 0x10000001
    
    ; ************[CURLE]***************
    CURLE_OK                          := 0
    CURLE_UNSUPPORTED_PROTOCOL        := 1
    CURLE_FAILED_INIT                 := 2
    CURLE_URL_MALFORMAT               := 3
    CURLE_OBSOLETE4                   := 4          ; NOT USED
    CURLE_COULDNT_RESOLVE_PROXY       := 5
    CURLE_COULDNT_RESOLVE_HOST        := 6
    CURLE_COULDNT_CONNECT             := 7
    CURLE_FTP_WEIRD_SERVER_REPLY      := 8
    CURLE_REMOTE_ACCESS_DENIED        := 9          ; A service was denied by the server
                                                    ; due to lack of access - when login fails
                                                    ; this is not returned.     
    CURLE_OBSOLETE10                  := 10         ; NOT USED
    CURLE_FTP_WEIRD_PASS_REPLY        := 11
    CURLE_OBSOLETE12                  := 12         ; NOT USED
    CURLE_FTP_WEIRD_PASV_REPLY        := 13
    CURLE_FTP_WEIRD_227_FORMAT        := 14
    CURLE_FTP_CANT_GET_HOST           := 15
    CURLE_OBSOLETE16                  := 16         ; NOT USED
    CURLE_FTP_COULDNT_SET_TYPE        := 17
    CURLE_PARTIAL_FILE                := 18
    CURLE_FTP_COULDNT_RETR_FILE       := 19
    CURLE_OBSOLETE20                  := 20         ; NOT USED
    CURLE_QUOTE_ERROR                 := 21         ; quote command failure
    CURLE_HTTP_RETURNED_ERROR         := 22
    CURLE_WRITE_ERROR                 := 23
    CURLE_OBSOLETE24                  := 24         ; NOT USED
    CURLE_UPLOAD_FAILED               := 25         ; failed upload "command"
    CURLE_READ_ERROR                  := 26         ; couldn't open/read from file
    CURLE_OUT_OF_MEMORY               := 27         ; Note: CURLE_OUT_OF_MEMORY may 
                                                    ; sometimes indicate a conversion error
                                                    ; instead of a memory allocation error
                                                    ; if CURL_DOES_CONVERSIONS is defined
    CURLE_OPERATION_TIMEDOUT          := 28         ; the timeout time was reached
    CURLE_OBSOLETE29                  := 29         ; NOT USED
    CURLE_FTP_PORT_FAILED             := 30         ; FTP PORT operation failed
    CURLE_FTP_COULDNT_USE_REST        := 31         ; the REST command failed 
    CURLE_OBSOLETE32                  := 32         ; NOT USED 
    CURLE_RANGE_ERROR                 := 33         ; RANGE "command" didn't work 
    CURLE_HTTP_POST_ERROR             := 34 
    CURLE_SSL_CONNECT_ERROR           := 35         ; wrong when connecting with SSL 
    CURLE_BAD_DOWNLOAD_RESUME         := 36         ; couldn't resume download 
    CURLE_FILE_COULDNT_READ_FILE      := 37 
    CURLE_LDAP_CANNOT_BIND            := 38 
    CURLE_LDAP_SEARCH_FAILED          := 39 
    CURLE_OBSOLETE40                  := 40         ; NOT USED 
    CURLE_FUNCTION_NOT_FOUND          := 41 
    CURLE_ABORTED_BY_CALLBACK         := 42 
    CURLE_BAD_FUNCTION_ARGUMENT       := 43 
    CURLE_OBSOLETE44                  := 44         ; NOT USED 
    CURLE_INTERFACE_FAILED            := 45         ; CURLOPT_INTERFACE failed 
    CURLE_OBSOLETE46                  := 46         ; NOT USED 
    CURLE_TOO_MANY_REDIRECTS          := 47         ; catch endless redirect loops 
    CURLE_UNKNOWN_TELNET_OPTION       := 48         ; User specified an unknown option 
    CURLE_TELNET_OPTION_SYNTAX        := 49         ; Malformed telnet option 
    CURLE_OBSOLETE50                  := 50         ; NOT USED 
    CURLE_PEER_FAILED_VERIFICATION    := 51         ; peer's certificate or fingerprint wasn't verified correctly
    CURLE_GOT_NOTHING                 := 52         ; when this is a specific error 
    CURLE_SSL_ENGINE_NOTFOUND         := 53         ; SSL crypto engine not found 
    CURLE_SSL_ENGINE_SETFAILED        := 54         ; can not set SSL crypto engine as
                                                    ; default 
    CURLE_SEND_ERROR                  := 55         ; failed sending network data 
    CURLE_RECV_ERROR                  := 56         ; failure in receiving network data 
    CURLE_OBSOLETE57                  := 57         ; NOT IN USE 
    CURLE_SSL_CERTPROBLEM             := 58         ; problem with the local certificate 
    CURLE_SSL_CIPHER                  := 59         ; couldn't use specified cipher 
    CURLE_SSL_CACERT                  := 60         ; problem with the CA cert (path?) 
    CURLE_BAD_CONTENT_ENCODING        := 61         ; Unrecognized transfer encoding 
    CURLE_LDAP_INVALID_URL            := 62         ; Invalid LDAP URL 
    CURLE_FILESIZE_EXCEEDED           := 63         ; Maximum file size exceeded 
    CURLE_USE_SSL_FAILED              := 64         ; Requested FTP SSL level failed 
    CURLE_SEND_FAIL_REWIND            := 65         ; Sending the data requires a rewind
                                                    ; that failed 
    CURLE_SSL_ENGINE_INITFAILED       := 66         ; failed to initialise ENGINE 
    CURLE_LOGIN_DENIED                := 67         ; user, password or similar was not
                                                    ; accepted and we failed to login 
    CURLE_TFTP_NOTFOUND               := 68         ; file not found on server 
    CURLE_TFTP_PERM                   := 69         ; permission problem on server 
    CURLE_REMOTE_DISK_FULL            := 70         ; out of disk space on server 
    CURLE_TFTP_ILLEGAL                := 71         ; Illegal TFTP operation 
    CURLE_TFTP_UNKNOWNID              := 72         ; Unknown transfer ID 
    CURLE_REMOTE_FILE_EXISTS          := 73         ; File already exists 
    CURLE_TFTP_NOSUCHUSER             := 74         ; No such user 
    CURLE_CONV_FAILED                 := 75         ; conversion failed 
    CURLE_CONV_REQD                   := 76         ; caller must register conversion
                                                    ; callbacks using curl_easy_setopt options
                                                    ; CURLOPT_CONV_FROM_NETWORK_FUNCTION,
                                                    ; CURLOPT_CONV_TO_NETWORK_FUNCTION, and
                                                    ; CURLOPT_CONV_FROM_UTF8_FUNCTION
    CURLE_SSL_CACERT_BADFILE          := 77         ; could not load CACERT file, missing or wrong format 
    CURLE_REMOTE_FILE_NOT_FOUND       := 78         ; remote file not found 
    CURLE_SSH                         := 79         ; error from the SSH layer, somewhat
                                                    ; generic so the error message will be of
                                                    ; interest when this has happened 
    CURLE_SSL_SHUTDOWN_FAILED         := 80         ; Failed to shut down the SSL connection 
    CURLE_AGAIN                       := 81         ; socket is not ready for send/recv,
                                                    ; wait till it's ready and try again (Added in 7.18.2) 
    CURLE_SSL_CRL_BADFILE             := 82         ; could not load CRL file, 
                                                    ; missing or wrong format (Added in 7.19.0)
    CURLE_SSL_ISSUER_ERROR            := 83         ; Issuer check failed.  (Added in 7.19.0) 
    CURLE_FTP_PRET_FAILED             := 84         ; a PRET command failed 
    CURLE_RTSP_CSEQ_ERROR             := 85         ; mismatch of RTSP CSeq numbers 
    CURLE_RTSP_SESSION_ERROR          := 86         ; mismatch of RTSP Session Identifiers 
    CURLE_FTP_BAD_FILE_LIST           := 87         ; unable to parse FTP file list 
    CURLE_CHUNK_FAILED                := 88         ; chunk callback reported error

	lvar := %var%, val != "" ? %var% := val
    return lvar
}

FILE(var, val=""){
    static
    
    ; File Helper Constants
    ; tCreate
    
    CREATE_NEW                        := 1
    CREATE_ALWAYS                     := 2
    OPEN_EXISTING                     := 3
    OPEN_ALWAYS                       := 4
    TRUNCATE_EXISTING                 := 5
    
    ; tAccess
    
    GENERIC_READ                      := 0x80000000
    GENERIC_WRITE                     := 0x40000000
    GENERIC_RW                        := (GENERIC_READ | GENERIC_WRITE)
    GENERIC_EXECUTE                   := 0x20000000
    GENERIC_ALL                       := 0x10000000
    
    ; tShare
    
    FILE_SHARE_READ                   := 0x00000001
    FILE_SHARE_WRITE                  := 0x00000002
    FILE_SHARE_DELETE                 := 0x00000004
    FILE_SHARE_ALL                    := 0x00000007
    
    ; tFlags
    
    FILE_ATTRIBUTE_ARCHIVE            := 0x20
    FILE_ATTRIBUTE_ENCRYPTED          := 0x4000
    FILE_ATTRIBUTE_HIDDEN             := 0x2
    FILE_ATTRIBUTE_NORMAL             := 0x80
    FILE_ATTRIBUTE_OFFLINE            := 0x1000
    FILE_ATTRIBUTE_READONLY           := 0x1
    FILE_ATTRIBUTE_SYSTEM             := 0x4
    FILE_ATTRIBUTE_TEMPORARY          := 0x100
    
    FILE_FLAG_BACKUP_SEMANTICS        := 0x02000000
    FILE_FLAG_DELETE_ON_CLOSE         := 0x04000000
    FILE_FLAG_NO_BUFFERING            := 0x20000000
    FILE_FLAG_OPEN_NO_RECALL          := 0x00100000
    FILE_FLAG_OPEN_REPARSE_POINT      := 0x00200000
    FILE_FLAG_OVERLAPPED              := 0x40000000
    FILE_FLAG_POSIX_SEMANTICS         := 0x0100000
    FILE_FLAG_RANDOM_ACCESS           := 0x10000000
    FILE_FLAG_SEQUENTIAL_SCAN         := 0x08000000
    FILE_FLAG_WRITE_THROUGH           := 0x80000000

	lvar := %var%, val != "" ? %var% := val
    return lvar
}
