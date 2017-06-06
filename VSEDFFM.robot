*** Setting ***
Library     SSHLibrary
Library     String
Resource    Resource/keyword.robot

Suite Setup            Open Connection And Log In
Suite Teardown         Close All Connections

Test Setup              Connect To Database AirManifest
Test Teardown           Disconnect From Database

*** Variables ***

#Connection Info
${Host}             10.2.3.72
${Username}         root
${Password}         netbay@123

# Change data for test
${Indicator}        EXPORT
${fileName}         FFM_DataTest
${FlightNo}         TG 600
${FlightDate}       05JUN


*** Testcases ***
Put Message FFM From Local to Server
      Put File From Local to Server             ${Indicator}      ${fileName}
      Check File in Server should visible       ${fileName}   
      Prepare message to test                   ${fileName}       ${FlightNo}       ${FlightDate}

Parser Message FFM and Generate XML to Output folder
      Run Script aim_main to parser Message
      Check File should delete in Input path              ${fileName} 
      Check File should transfer in backup folder         ${fileName} 
      Check database Flight should insert and status is Send      22        ${FlightNo}       ${FlightDate}
      Output folder should visible XML File                       22        ${FlightNo}       ${FlightDate}

Sign XML File and Send to gateway
      Run Script sign XML to send gateway
      Output folder should not visible XML files                  22        ${FlightNo}       ${FlightDate}

# Receive Response from gateway and update status
#      Run script distributeCusres
#      Check response from gateway in folder Input cusres TG should visible
#      Check Database Flight should status Accepted


*** Keywords ***
Open Connection And Log In
    Open Connection     ${Host}         port=22
    Login               ${Username}     ${Password}     delay=0.5

Prepare message to test 
    [Arguments]        ${fileName}      ${flight}       ${FlightDate}
    SSHLibrary.Start Command    cat /var/www/html/manifest/AIM_Files/Input_TG/${fileName}.txt
    ${GetContentVSED}       Read Command Output
    ${GetLineContent}       Get Line        ${GetContentVSED}       1

    ${Old_flightNo}         String.Get Substring        ${GetLineContent}       2        8
    ${Old_flightDate}       String.Get Substring        ${GetLineContent}       9       14
    ${Old_flightDate2}      String.Get Substring        ${GetLineContent}       32      37

    ${New_flightNo}         String.Replace String       ${flight}       ${SPACE}        0

    SSHLibrary.Execute Command    replace "${Old_flightNo}" "${New_flightNo}" -- /var/www/html/manifest/AIM_Files/Input_TG/${fileName}.txt
    SSHLibrary.Execute Command    replace "${Old_flightDate}" "${FlightDate}" -- /var/www/html/manifest/AIM_Files/Input_TG/${fileName}.txt
    SSHLibrary.Execute Command    replace "${Old_flightDate2}" "${FlightDate}" -- /var/www/html/manifest/AIM_Files/Input_TG/${fileName}.txt


Check database Flight should insert and status is Send
    [Arguments]      ${Indicator}       ${FlightNo}     ${FlightDate}
        ${FlightNoToQuery}      Remove String           ${FlightNo}         ${SPACE}
        
        ${ConvFlightDate}               Convert Date                ${FlightDate}           date_format=%d%b
        ${FlightDateResult}             String.Get Substring        ${ConvFlightDate}       0     10
        ${CurrentDate}                  Get Current Date
        ${FlightDateReplaceYear}        String.Get Substring        ${CurrentDate}          0       4
        ${FlightDateToQuery}            String.Replace String       ${FlightDateResult}     1900        ${FlightDateReplaceYear}
                
        ${FlightData}    Query    SELECT vsedhead.VH_Status FROM vsedhead LEFT JOIN vseddetail on vsedhead.VH_ID = vseddetail.VD_HID WHERE vsedhead.VH_TransportMeansJourneyID = '${FlightNoToQuery}' AND vseddetail.VD_FlightDate = '${FlightDateToQuery}' and vsedhead.VH_DocumentType = '${Indicator}'
        Should Be Equal     ${FlightData[0][0]}    Sent


Output folder should visible XML File
    [Arguments]       ${Indicator}      ${FlightNo}     ${FlightDate}
        ${FlightNoToQuery}      Remove String           ${FlightNo}         ${SPACE}
        
        ${ConvFlightDate}               Convert Date                ${FlightDate}           date_format=%d%b
        ${FlightDateResult}             String.Get Substring        ${ConvFlightDate}       0     10
        ${CurrentDate}                  Get Current Date
        ${FlightDateReplaceYear}        String.Get Substring        ${CurrentDate}          0       4
        ${FlightDateToQuery}            String.Replace String       ${FlightDateResult}     1900        ${FlightDateReplaceYear}
    
        ${DocumentNo}    Query    SELECT vsedhead.VH_DocumentNumber FROM vsedhead LEFT JOIN vseddetail on vsedhead.VH_ID = vseddetail.VD_HID WHERE vsedhead.VH_TransportMeansJourneyID = '${FlightNoToQuery}' AND vseddetail.VD_FlightDate = '${FlightDateToQuery}' and vsedhead.VH_DocumentType = '${Indicator}'

        SSHLibrary.File Should Exist    /var/www/html/manifest/AIM_Files/Output_XML/TG/VSED_${DocumentNo[0][0]}.xml


Output folder should not visible XML files
    [Arguments]       ${Indicator}      ${FlightNo}     ${FlightDate}
        ${FlightNoToQuery}      Remove String           ${FlightNo}         ${SPACE}
        
        ${ConvFlightDate}               Convert Date                ${FlightDate}           date_format=%d%b
        ${FlightDateResult}             String.Get Substring        ${ConvFlightDate}       0     10
        ${CurrentDate}                  Get Current Date
        ${FlightDateReplaceYear}        String.Get Substring        ${CurrentDate}          0       4
        ${FlightDateToQuery}            String.Replace String       ${FlightDateResult}     1900        ${FlightDateReplaceYear}
    
        ${DocumentNo}    Query    SELECT vsedhead.VH_DocumentNumber FROM vsedhead LEFT JOIN vseddetail on vsedhead.VH_ID = vseddetail.VD_HID WHERE vsedhead.VH_TransportMeansJourneyID = '${FlightNoToQuery}' AND vseddetail.VD_FlightDate = '${FlightDateToQuery}' and vsedhead.VH_DocumentType = '${Indicator}'

        SSHLibrary.File Should Not Exist    /var/www/html/manifest/AIM_Files/Output_XML/TG/VSED_${DocumentNo[0][0]}.xml