*** Settings ***
Library           Collections
Library           SoapLibrary.py
Library           OperatingSystem

*** Variables ***


*** Test Cases ***
Test read
    Create Soap Client    http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx?wsdl
    ${response}    Call SOAP Method With XML    ${CURDIR}/Request_CalcPrecoPrazo.xml
    ${valor}    Get Data From XML By Tag    ${response}    ValorSemAdicionais
    Log    ${valor}
    should be equal    23,50    ${valor}

Test read utf8
    Create Soap Client    http://ws.cdyne.com/ip2geo/ip2geo.asmx?wsdl
    ${response}    Call SOAP Method With XML    ${CURDIR}/request_ip.xml
    ${City}    Get Data From XML By Tag    ${response}    City
    Log    ${City}
    should be equal as strings    Fundão    ${City}

Test Read tags with index
    Create Soap Client    http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx?wsdl
    ${response}    Call SOAP Method With XML    ${CURDIR}/Request_ListaServicos.xml
    ${codigo}    Get Data From XML By Tag    ${response}    codigo    index=99
    Log    ${codigo}
    should be equal as integers    11835    ${codigo}

Test Edit and Read
    Create Soap Client    http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx?wsdl
    ${dict}    Create Dictionary    tem:sCepDestino=80020000    tem:nVlPeso=4
    ${xml_edited}    Edit XML Request    ${CURDIR}/Request_CalcPrecoPrazo.xml    ${dict}    New_Request_CalcPrecoPrazo
    ${response}    Call SOAP Method With XML    ${xml_edited}
    ${valor}    Get Data From XML By Tag    ${response}    ValorSemAdicionais
    Log    ${valor}
    should be equal    57,80    ${valor}

Test Response to Dict
    Create Soap Client    http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx?wsdl
    ${response}    Call SOAP Method With XML    ${CURDIR}/Request_CalcPrecoPrazo.xml
    ${dict_response}    Convert XML Response to Dictionary    ${response}
    Log    ${dict_response}
    ${body}    Get From Dictionary    ${dict_response}    Body
    ${calcprecoprazoresponse}    Get From Dictionary    ${body}    CalcPrecoPrazoResponse
    ${calcprecoprazoresult}    Get From Dictionary    ${calcprecoprazoresponse}    CalcPrecoPrazoResult
    ${servicos}    Get From Dictionary    ${calcprecoprazoresult}    Servicos
    ${cservico}    Get From Dictionary    ${servicos}    cServico
    ${valorsemadicionais}    Get From Dictionary    ${cservico}    ValorSemAdicionais
    Log    ${valorsemadicionais}
    should be equal    23,50    ${valorsemadicionais}

Test Save File Response
    Create Soap Client    http://ws.cdyne.com/ip2geo/ip2geo.asmx?wsdl
    ${response}    Call SOAP Method With XML    ${CURDIR}/request_ip.xml
    ${file}    Save XML Response File    ${response}    response_test
    log    ${file}