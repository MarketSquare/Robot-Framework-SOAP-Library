*** Settings ***
Library           ../SoapLibrary/
Library           Collections
Library           OperatingSystem

*** Variables ***
${requests_dir}                      ${CURDIR}${/}Requests
${wsdl_correios_price_calculator}    http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx?wsdl
${wsdl_ip_geo}                       http://ws.cdyne.com/ip2geo/ip2geo.asmx?wsdl

*** Test Cases ***
Test read
    Create Soap Client    ${wsdl_correios_price_calculator}
    ${response}    Call SOAP Method With XML    ${requests_dir}${/}Request_CalcPrecoPrazo.xml
    ${valor}    Get Data From XML By Tag    ${response}    ValorSemAdicionais
    should be equal    23,50    ${valor}

Test read utf8
    Create Soap Client    ${wsdl_ip_geo}
    ${response}    Call SOAP Method With XML    ${requests_dir}${/}request_ip.xml
    ${City}    Get Data From XML By Tag    ${response}    City
    should be equal as strings    Fundão    ${City}

Test Read tags with index
    Create Soap Client    ${wsdl_correios_price_calculator}
    ${response}    Call SOAP Method With XML    ${requests_dir}${/}Request_ListaServicos.xml
    ${code}    Get Data From XML By Tag    ${response}    codigo    index=99
    should be equal as integers    11835    ${code}

Test Edit and Read
    Create Soap Client    ${wsdl_correios_price_calculator}
    ${dict}    Create Dictionary    tem:sCepDestino=80020000    tem:nVlPeso=4
    ${xml_edited}    Edit XML Request    ${requests_dir}${/}Request_CalcPrecoPrazo.xml    ${dict}    New_Request_CalcPrecoPrazo
    ${response}    Call SOAP Method With XML    ${xml_edited}
    ${value}    Get Data From XML By Tag    ${response}    ValorSemAdicionais
    should be equal    57,80    ${value}

Test Response to Dict
    Create Soap Client    ${wsdl_correios_price_calculator}
    ${response}    Call SOAP Method With XML    ${requests_dir}${/}Request_CalcPrecoPrazo.xml
    ${dict_response}    Convert XML Response to Dictionary    ${response}
    ${body}    Get From Dictionary    ${dict_response}    Body
    ${calcprecoprazoresponse}    Get From Dictionary    ${body}    CalcPrecoPrazoResponse
    ${calcprecoprazoresult}    Get From Dictionary    ${calcprecoprazoresponse}    CalcPrecoPrazoResult
    ${servicos}    Get From Dictionary    ${calcprecoprazoresult}    Servicos
    ${cservico}    Get From Dictionary    ${servicos}    cServico
    ${valorsemadicionais}    Get From Dictionary    ${cservico}    ValorSemAdicionais
    should be equal    23,50    ${valorsemadicionais}

Test Save File Response
    Create Soap Client    ${wsdl_ip_geo}
    ${response}    Call SOAP Method With XML    ${requests_dir}${/}request_ip.xml
    ${file}    Save XML To File    ${response}    ${requests_dir}    response_test

