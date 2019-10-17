*** Settings ***
Library           ../SoapLibrary/
Library           Collections
Library           OperatingSystem

*** Variables ***
${requests_dir}                      ${CURDIR}${/}Requests
${wsdl_correios_price_calculator}    http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx?wsdl
${wsdl_ip_geo}                       http://ws.cdyne.com/ip2geo/ip2geo.asmx?wsdl
${wsdl_calculator}                   http://www.dneonline.com/calculator.asmx?wsdl

*** Test Cases ***
Test read
    Create Soap Client    ${wsdl_calculator}
    ${response}    Call SOAP Method With XML    ${requests_dir}${/}Request_Calculator.xml
    ${result}    Get Data From XML By Tag    ${response}    AddResult
    should be equal    8    ${result}

Test read utf8
    Create Soap Client    ${wsdl_ip_geo}
    ${response}    Call SOAP Method With XML    ${requests_dir}${/}request_ip.xml
    ${City}    Get Data From XML By Tag    ${response}    City
    should be equal as strings    Fundão    ${City}

Test Read tags with index
    Create Soap Client    ${wsdl_correios_price_calculator}
    ${response}    Call SOAP Method With XML    ${requests_dir}${/}Request_ListaServicos.xml
    ${codigo}    Get Data From XML By Tag    ${response}    codigo    index=99
    should be equal as integers    11835    ${codigo}

Test Edit and Read
    Remove File    ${requests_dir}${/}New_Request_Calculator.xml
    Create Soap Client    ${wsdl_calculator}
    ${dict}    Create Dictionary    tem:intA=9    tem:intB=5
    ${xml_edited}    Edit XML Request    ${requests_dir}${/}Request_Calculator.xml    ${dict}    New_Request_Calculator
    ${response}    Call SOAP Method With XML    ${xml_edited}
    ${result}    Get Data From XML By Tag    ${response}    AddResult
    should be equal    14    ${result}
    Should Exist    ${requests_dir}${/}New_Request_Calculator.xml

Test Response to Dict
    Create Soap Client    ${wsdl_correios_price_calculator}
    ${response}    Call SOAP Method With XML    ${requests_dir}${/}Request_CalcPrecoPrazo.xml
    ${dict_response}    Convert XML Response to Dictionary    ${response}
    ${type}    evaluate    str(type(${dict_response}))
    Should Contain    ${type}    'dict'
    ${body}    Get From Dictionary    ${dict_response}    Body
    ${calcprecoprazoresponse}    Get From Dictionary    ${body}    CalcPrecoPrazoResponse
    ${calcprecoprazoresult}    Get From Dictionary    ${calcprecoprazoresponse}    CalcPrecoPrazoResult
    ${servicos}    Get From Dictionary    ${calcprecoprazoresult}    Servicos
    ${cservico}    Get From Dictionary    ${servicos}    cServico
    ${valorsemadicionais}    Get From Dictionary    ${cservico}    ValorSemAdicionais
    should be equal    24,90    ${valorsemadicionais}

Test Save File Response
    Remove File    ${CURDIR}${/}response_test.xml
    Create Soap Client    ${wsdl_ip_geo}
    ${response}    Call SOAP Method With XML    ${requests_dir}${/}request_ip.xml
    ${file}    Save XML To File    ${response}    ${CURDIR}    response_test
    Should Exist    ${CURDIR}${/}response_test.xml

Test Call Soap Method
    Create Soap Client    ${wsdl_calculator}
    ${response}    Call SOAP Method    Add    2    1
    should be equal as integers    3    ${response}
