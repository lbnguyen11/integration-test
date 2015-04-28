*** Settings ***
Documentation     Test suite for L2switch's Address Tracking using mininet OF13
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library     SSHLibrary

*** Variables ***
${start}=  sudo mn --controller=remote,ip=${CONTROLLER} --topo=linear,3 --switch ovsk,protocols=OpenFlow13 --mac

** Keywords ***
Start Suite
    Log    Start mininet
    Open Connection   ${MININET}     prompt=>   timeout=20
    Login With Public Key    ${MININET_USER}   ${USER_HOME}/.ssh/id_rsa   any
    Write    sudo ovs-vsctl set-manager ptcp:6644
    Read Until    >
    Write    sudo mn -c
    Read Until    >
    Read Until    >
    Read Until    >
    Write    ${start}
    Read Until    mininet>
    Sleep               30
Stop Suite
    Close Connection