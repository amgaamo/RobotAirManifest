*** Setting ***
Library     SSHLibrary
Library     String
Resource    Resource/keyword.robot

Suite Setup            Open Connection And Log In
Suite Teardown         Close All Connections

*** Variables ***

#Connection Info
${Host}             10.2.3.72
${Username}         root
${Password}         netbay@123


*** Testcases ***
Put Message MFI From Local to Server
      Put File From Local to Server             EXPORT      FFM_DataTest
      Check File in Server should visible       FFM_DataTest    
      Prepare message to test                   FFM_DataTest        TG 625      04062017

# Parser Message MFI and Generate XML to Output folder
#       Run Script aim_main to parser Message
#       Check input path File should delete
#       File should transfer in backup folder
#       Check database Flight should status Send
#       Output folder should visible XML Files

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
    SSHLibrary.Start Command    cat /var/www/html/manifest/AIM_Files/Input_TG/${fileName}.txt
    ${GetContentVSED}=    Read Command Output
    ${Old_flightNo}=    String.Get Substring    ${GetContentVSED}       3        9
    ${Old_flightDate}=    String.Get Substring    ${GetContentVSED}    10       18

    SSHLibrary.Execute Command    replace "${Old_flightNo}" "${flight}" -- /var/www/html/manifest/AIM_Files/Input_TG/${fileName}.txt
    SSHLibrary.Execute Command    replace "${Old_flightDate}" "${FlightDate}" -- /var/www/html/manifest/AIM_Files/Input_TG/${fileName}.txt
