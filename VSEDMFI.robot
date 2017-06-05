*** Setting ***
Library     SSHLibrary
Library     String
Resource    Resource/keyword.robot

Suite Setup             Open Connection And Log In
Suite Teardown          Close All Connections

Test Setup              Connect To Database AirManifest
Test Teardown           Disconnect From Database

*** Variables ***

#Connection Info
${Host}             10.2.3.72
${Username}         root
${Password}         netbay@123

# Change data for test
${Indicator}        IMPORT
${fileName}         MFI_DataTest 
${FlightNo}         TG 625
${FlightDate}       01062017


*** Testcases ***
Put Message MFI From Local to Server
      Put File From Local to Server             ${Indicator}      ${fileName}
      Check File in Server should visible       ${fileName}   
      Prepare message to test                   ${fileName}       ${FlightNo}       ${FlightDate}

Parser Message MFI and Generate XML to Output folder
      Run Script aim_main to parser Message
      Check File should delete in Input path              ${fileName} 
      Check File should transfer in backup folder         ${fileName} 
      Check database Flight should insert and status is Send      23        ${FlightNo}          ${FlightDate}
      Output folder should visible XML File                       23        ${FlightNo}          ${FlightDate}

# Sign XML File and Send to gateway
#       Run Script sign XML to send gateway
#       Output folder should not visible XML files

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
    SSHLibrary.Start Command        cat /var/www/html/manifest/AIM_Files/Input_TG/${fileName}.txt
    ${GetContentVSED}               Read Command Output
    ${Old_flightNo}                 String.Get Substring        ${GetContentVSED}       3        9
    ${Old_flightDate}               String.Get Substring        ${GetContentVSED}       10       18

    SSHLibrary.Execute Command    replace "${Old_flightNo}" "${flight}" -- /var/www/html/manifest/AIM_Files/Input_TG/${fileName}.txt
    SSHLibrary.Execute Command    replace "${Old_flightDate}" "${FlightDate}" -- /var/www/html/manifest/AIM_Files/Input_TG/${fileName}.txt


Check database Flight should insert and status is Send
    [Arguments]      ${Indicator}       ${FlightNo}     ${FlightDate}
        ${FlightNoToQuery}      Remove String           ${FlightNo}         ${SPACE}
        ${ConvFlightDate}       Convert Date            ${FlightDate}       date_format=%d%m%Y
        ${FlightDateToQuery}    String.Get Substring    ${ConvFlightDate}       0     10
    
        ${FlightData}    Query    SELECT vsedhead.VH_DocumentType,vsedhead.VH_Status FROM vsedhead LEFT JOIN vseddetail on vsedhead.VH_ID = vseddetail.VD_HID WHERE vsedhead.VH_TransportMeansJourneyID = '${FlightNoToQuery}' AND vseddetail.VD_FlightDate = '${FlightDateToQuery}' AND vsedhead.VH_DocumentType = '${Indicator}'
        Should Be Equal    ${FlightData[0][1]}    Sent


Output folder should visible XML File
    [Arguments]       ${Indicator}      ${FlightNo}     ${FlightDate}
        ${FlightNoToQuery}      Remove String           ${FlightNo}         ${SPACE}
        ${ConvFlightDate}       Convert Date            ${FlightDate}       date_format=%d%m%Y
        ${FlightDateToQuery}    String.Get Substring    ${ConvFlightDate}       0     10
    
        ${DocumentNo}    Query    SELECT vsedhead.VH_DocumentNumber FROM vsedhead LEFT JOIN vseddetail on vsedhead.VH_ID = vseddetail.VD_HID WHERE vsedhead.VH_TransportMeansJourneyID = '${FlightNoToQuery}' AND vseddetail.VD_FlightDate = '${FlightDateToQuery}' AND vsedhead.VH_DocumentType = '${Indicator}'

        SSHLibrary.File Should Exist    /var/www/html/manifest/AIM_Files/Output_XML/TG/VSED_${DocumentNo[0][0]}.xml