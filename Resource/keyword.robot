*** Setting ***
Library     SSHLibrary
Library     String
Library     DateTime  
Library     DatabaseLibrary   


*** Keywords ***

Connect To Database AirManifest
    Connect To Database    pymysql    manifest_air_test    pattaraporn    pattaraporn@netbay    10.1.3.72    3306

Put File From Local to Server
    [Arguments]        ${Indicator}     ${fileName}
    SSHLibrary.Put File    ${CURDIR}\\DataTestMSG\\${Indicator}\\${fileName}.txt    destination=/var/www/html/manifest/AIM_Files/Input_TG    mode=0744

Check File in Server should visible
    [Arguments]        ${fileName}    
    SSHLibrary.File Should Exist    /var/www/html/manifest/AIM_Files/Input_TG/${fileName}.txt


Run Script aim_main to parser Message
    SSHLibrary.Start Command    cd /var/www/html/manifest/IE5DEV.AIM/AIM_TG/ ; php aim_main.php
    ${parsermsg}=    Read Command Output
    Log to console    ${parsermsg}


Check File should delete in Input path
    [Arguments]     ${fileName}
    SSHLibrary.File Should Not Exist    /var/www/html/manifest/AIM_Files/Input_TG/${fileName}.txt


Check File should transfer in backup folder
    [Arguments]     ${fileName}
        ${CurrentDate}      Get Current Date
        ${Year}             String.Get Substring    ${CurrentDate}      0       4
        ${Month}            String.Get Substring    ${CurrentDate}      5       7         
        ${Date}             String.Get Substring    ${CurrentDate}      8       10

    SSHLibrary.File Should Exist    /var/www/html/manifest/AIM_Files/Input_TG/backup/${Year}_${Month}_${Date}/${fileName}.txt

Run Script sign XML to send gateway
     ${SignScript}=    SSHLibrary.Execute Command    cd /var/www/html/manifest/AIM_Files/signManifestHttpOpt/ ; java -Dfile.encoding=utf-8 -jar SignOnlyHttpOption.jar -s /var/www/html/manifest/AIM_Files/Output_XML/TG -o /var/netbay/vas/ebxml/home/tg_test199/inbox -c /var/www/html/manifest/AIM_Files/CER/THAI_AIRWAYS.p12 -p 'Thaiair*7'
     Log to console    ${SignScript}


Run script distributeCusres
    SSHLibrary.Start Command    cd /var/www/html/manifest/IE5DEV.AIM/ACCS ; php distributeCusres.php
    ${Distribute}=    Read Command Output
    Log to console    ${Distribute}

    SSHLibrary.Start Command    cd /var/www/html/manifest/IE5DEV.AIM/AIM_TG/ ; php aim_main.php
    ${UpdateResponse}=    Read Command Output
    Log to console    ${UpdateResponse}

    /var/www/html/manifest/AIM_Files/Input_Cusres/TG