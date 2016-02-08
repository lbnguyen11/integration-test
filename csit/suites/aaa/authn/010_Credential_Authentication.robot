*** Settings ***
Documentation     AAA System Tests
Suite Teardown    Delete All Sessions
Test Setup        Log Testcase Start To Controller Karaf
Library           Collections
Library           OperatingSystem
Library           String
Library           HttpLibrary.HTTP
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/AAAKeywords.robot

*** Variables ***

*** Test Cases ***
Get Token With Valid Username And Password
    [Documentation]    Sanity test to ensure default user/password can get a token
    ${auth_token}=    Get Auth Token
    Should Be String    ${auth_token}
    Log    Token: ${auth_token}
    Validate Token Format    ${auth_token}

Fail To Get Token With Invalid Username And Password
    [Documentation]    Negative test to verify invalid user/password is denied a token
    ${bad_user}=    Set Variable    notTheAdmin
    ${auth_data}=    Create Auth Data    ${bad_user}    notTheAdminPassword
    ${resp}=    AAA Login    ${ODL_SYSTEM_IP}    ${auth_data}
    Should Be Equal As Strings    ${resp.status_code}    401
    Log    ${resp.content}
    ${error_msg}=    Extract Value From Content    ${resp.content}    /error    strip
    Should Contain    ${error_msg}    User :${bad_user} does not exist

Create Token with Client Authorization
    [Documentation]    Get a token using client domain
    ${auth_token}=    Get Auth Token    ${USER}    ${PWD}    ${SCOPE}    dlux    secrete
    Should Be String    ${auth_token}
    Log    Token: ${auth_token}
    Validate Token Format    ${auth_token}

Token Authentication In REST Request
    [Documentation]    Use a token to make a successful REST transaction
    ${auth_token}=    Get Auth Token
    Make REST Transaction    200    ${auth_token}

Revoke Token And Verify Transaction Fails
    [Documentation]    negative test to revoke valid token and check that REST transaction fails
    ${auth_token}=    Get Auth Token
    Make REST Transaction    200    ${auth_token}
    Revoke Auth Token    ${auth_token}
    Make REST Transaction    401    ${auth_token}

Disable Authentication And Re-Enable Authentication
    [Documentation]    Toggles authentication off and verifies that no login credentials are needed for REST transactions.
    ...    Test has been disabled due to the fact that this interface has changed.  Authentication is now disabled
    ...    through modification of shiro.ini, which requires controller restart and is not suit for this test.
    [Tags]    exclude
    Disable Authentication On Controller    ${ODL_SYSTEM_IP}
    Wait Until Keyword Succeeds    10s    1s    Make REST Transaction    200
    Enable Authentication On Controller    ${ODL_SYSTEM_IP}
    Wait Until Keyword Succeeds    10s    1s    Validate That Authentication Fails With Wrong Token
    ${auth_token}=    Get Auth Token
    Make REST Transaction    200    ${auth_token}
    [Teardown]    Report_Failure_Due_To_Bug    4922

*** Keywords ***
Validate That Authentication Fails With Wrong Token
    ${bad_token}=    Set Variable    notARealToken
    Make REST Transaction    401    ${bad_token}

Make REST Transaction
    [Arguments]    ${expected_status_code}    ${auth_data}=${EMPTY}
    Create Session    ODL_SESSION    http://${ODL_SYSTEM_IP}:8181
    ${headers}=    Create Dictionary    Content-Type=application/x-www-form-urlencoded
    Run Keyword If    "${auth_data}" != "${EMPTY}"    Set To Dictionary    ${headers}    Authorization    Bearer ${auth_data}
    ${resp}=    RequestsLibrary.GET Request    ODL_SESSION    ${MODULES_API}    headers=${headers}
    Log    STATUS_CODE: ${resp.status_code} CONTENT: ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${expected_status_code}
