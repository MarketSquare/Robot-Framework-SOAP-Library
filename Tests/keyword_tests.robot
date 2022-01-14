*** Settings ***
Library           ../SoapLibrary/
Library           Collections
Library           OperatingSystem
Library           XML    use_lxml=True
Library           Process

*** Variables ***
${requests_dir}                      ${CURDIR}${/}Requests
${wsdl_correios_price_calculator}    http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx?wsdl
${wsdl_ip_geo}                       http://ws.cdyne.com/ip2geo/ip2geo.asmx?wsdl
${wsdl_calculator}                   http://www.dneonline.com/calculator.asmx?wsdl
${request_string}                    <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/"><soapenv:Header/><soapenv:Body><tem:Add><tem:intA>3</tem:intA><tem:intB>5</tem:intB></tem:Add></soapenv:Body></soapenv:Envelope>
${request_string_500}                <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/"><soapenv:Header/><soapenv:Body><tem:Add><tem:intA>3</tem:intA><tem:intB>a</tem:intB></tem:Add></soapenv:Body></soapenv:Envelope>

*** Test Cases ***
Test_connections
    log     testing    WARN
    ${result}    Run Process    curl www.dneonline.com    shell=True
    Log    ${result.stdout}    WARN



Test read
    Create Soap Client    ${wsdl_calculator}
    ${response}    Call SOAP Method With XML    ${requests_dir}${/}Request_Calculator.xml
    ${result}    Get Data From XML By Tag    ${response}    AddResult
    should be equal    8    ${result}

Test read string xml
    Create Soap Client    ${wsdl_calculator}
    ${response}    Call SOAP Method With String XML  ${request_string}
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

Test Edit XML Request 1
    [Documentation]    Change all names, dates and reasons tags
    ${new_value_dict}    Create Dictionary    startDate=15-01-2020    name=Joaquim    Reason=1515
    ${xml_edited}    Edit XML Request    ${requests_dir}${/}request.xml    ${new_value_dict}    New_Request    repeated_tags=0
    ${new_value_dict}    Create Dictionary    startDate=16-01-2020    name2=Joao    Reason=1616
    ${xml_edited}    Edit XML Request    ${xml_edited}    ${new_value_dict}    New_Request    repeated_tags=1
    ${new_value_dict}    Create Dictionary    startDate=17-01-2020    Reason=1717
    ${xml_edited}    Edit XML Request    ${xml_edited}    ${new_value_dict}    New_Request    repeated_tags=2
    ${data}    Parse XML    ${requests_dir}${/}New_Request.xml    keep_clark_notation=True
    ${text_name}    Evaluate Xpath    ${data}    //name
    Should be equal    ${text_name[0].text}    Joaquim
    ${text_name2}    Evaluate Xpath    ${data}    //name2
    Should be equal    ${text_name2[0].text}    Joao
    ${text_date}    Evaluate Xpath    ${data}    //startDate
    Should be equal    ${text_date[0].text}    15-01-2020
    Should be equal    ${text_date[1].text}    16-01-2020
    Should be equal    ${text_date[2].text}    17-01-2020
    ${text_reason}    Evaluate Xpath    ${data}    //Reason
    Should be equal    ${text_reason[0].text}    1515
    Should be equal    ${text_reason[1].text}    1616
    Should be equal    ${text_reason[2].text}    1717

Test Edit XML Request 2
    [Documentation]    Change name, date and reason on tag 0
    ${new_value_dict}    Create Dictionary    startDate=20-01-2020    name=Maria    Reason=2020
    ${xml_edited}    Edit XML Request    ${requests_dir}${/}request.xml    ${new_value_dict}    New_Request    repeated_tags=0
    ${data}    Parse XML    ${requests_dir}${/}New_Request.xml    keep_clark_notation=True
    ${text_name}    Evaluate Xpath    ${data}    //name
    Should be equal    ${text_name[0].text}    Maria
    ${text_name2}    Evaluate Xpath    ${data}    //name2
    Should be equal    ${text_name2[0].text}    BBBB
    ${text_date}    Evaluate Xpath    ${data}    //startDate
    Should be equal    ${text_date[0].text}    20-01-2020
    Should be equal    ${text_date[1].text}    2019-06-03
    Should be equal    ${text_date[2].text}    2019-06-03
    ${text_reason}    Evaluate Xpath    ${data}    //Reason
    Should be equal    ${text_reason[0].text}    2020
    Should be equal    ${text_reason[1].text}    0000
    Should be equal    ${text_reason[2].text}    0000

Test Edit XML Request 3
    [Documentation]    Change name2, date and reason on tag 1
    ${new_value_dict}    Create Dictionary    startDate=22-01-2020    name2=Joana    Reason=2222
    ${xml_edited}    Edit XML Request    ${requests_dir}${/}request.xml    ${new_value_dict}    New_Request    repeated_tags=1
    ${data}    Parse XML    ${requests_dir}${/}New_Request.xml    keep_clark_notation=True
    ${text_name}    Evaluate Xpath    ${data}    //name
    Should be equal    ${text_name[0].text}    AAAAA
    ${text_name2}    Evaluate Xpath    ${data}    //name2
    Should be equal    ${text_name2[0].text}    Joana
    ${text_date}    Evaluate Xpath    ${data}    //startDate
    Should be equal    ${text_date[0].text}    2019-06-03
    Should be equal    ${text_date[1].text}    22-01-2020
    Should be equal    ${text_date[2].text}    2019-06-03
    ${text_reason}    Evaluate Xpath    ${data}    //Reason
    Should be equal    ${text_reason[0].text}    0000
    Should be equal    ${text_reason[1].text}    2222
    Should be equal    ${text_reason[2].text}    0000

Test Edit XML Request 4
    [Documentation]    Change date and Reason on tag 2
    ${new_value_dict}    Create Dictionary    startDate=25-01-2020    Reason=2525
    ${xml_edited}    Edit XML Request    ${requests_dir}${/}request.xml    ${new_value_dict}    New_Request    repeated_tags=2
    ${data}    Parse XML    ${requests_dir}${/}New_Request.xml    keep_clark_notation=True
    ${text_name}    Evaluate Xpath    ${data}    //name
    Should be equal    ${text_name[0].text}    AAAAA
    ${text_name2}    Evaluate Xpath    ${data}    //name2
    Should be equal    ${text_name2[0].text}    BBBB
    ${text_date}    Evaluate Xpath    ${data}    //startDate
    Should be equal    ${text_date[0].text}    2019-06-03
    Should be equal    ${text_date[1].text}    2019-06-03
    Should be equal    ${text_date[2].text}    25-01-2020
    ${text_reason}    Evaluate Xpath    ${data}    //Reason
    Should be equal    ${text_reason[0].text}    0000
    Should be equal    ${text_reason[1].text}    0000
    Should be equal    ${text_reason[2].text}    2525

Test Edit XML Request 5
    [Documentation]    Change name, date and reason in Tags 0 and 1
    ${new_value_dict}    Create Dictionary    startDate=15-01-2020    name=Joaquim    Reason=1515
    ${xml_edited}    Edit XML Request    ${requests_dir}${/}request.xml    ${new_value_dict}    New_Request    repeated_tags=0
    ${new_value_dict}    Create Dictionary    startDate=16-01-2020    name2=Joao    Reason=1616
    ${xml_edited}    Edit XML Request    ${xml_edited}    ${new_value_dict}    New_Request    repeated_tags=1
    ${data}    Parse XML    ${requests_dir}${/}New_Request.xml    keep_clark_notation=True
    ${text_name}    Evaluate Xpath    ${data}    //name
    Should be equal    ${text_name[0].text}    Joaquim
    ${text_name2}    Evaluate Xpath    ${data}    //name2
    Should be equal    ${text_name2[0].text}    Joao
    ${text_date}    Evaluate Xpath    ${data}    //startDate
    Should be equal    ${text_date[0].text}    15-01-2020
    Should be equal    ${text_date[1].text}    16-01-2020
    Should be equal    ${text_date[2].text}    2019-06-03
    ${text_reason}    Evaluate Xpath    ${data}    //Reason
    Should be equal    ${text_reason[0].text}    1515
    Should be equal    ${text_reason[1].text}    1616
    Should be equal    ${text_reason[2].text}    0000

Test Edit XML Request 6
    [Documentation]    Change name, date and reason in Tags 1 and 2
    ${new_value_dict}    Create Dictionary    startDate=15-01-2020    name2=Joaquim    Reason=1515
    ${xml_edited}    Edit XML Request    ${requests_dir}${/}request.xml    ${new_value_dict}    New_Request    repeated_tags=1
    ${new_value_dict}    Create Dictionary    startDate=16-01-2020    Reason=1616
    ${xml_edited}    Edit XML Request    ${xml_edited}    ${new_value_dict}    New_Request    repeated_tags=2
    ${data}    Parse XML    ${requests_dir}${/}New_Request.xml    keep_clark_notation=True
    ${text_name}    Evaluate Xpath    ${data}    //name
    Should be equal    ${text_name[0].text}    AAAAA
    ${text_name2}    Evaluate Xpath    ${data}    //name2
    Should be equal    ${text_name2[0].text}    Joaquim
    ${text_date}    Evaluate Xpath    ${data}    //startDate
    Should be equal    ${text_date[0].text}    2019-06-03
    Should be equal    ${text_date[1].text}    15-01-2020
    Should be equal    ${text_date[2].text}    16-01-2020
    ${text_reason}    Evaluate Xpath    ${data}    //Reason
    Should be equal    ${text_reason[0].text}    0000
    Should be equal    ${text_reason[1].text}    1515
    Should be equal    ${text_reason[2].text}    1616

Test Edit XML Request 7
    [Documentation]    Change only the name tag
    ${new_value_dict}    Create Dictionary    name=Carlota
    ${xml_edited}    Edit XML Request    ${requests_dir}${/}request.xml    ${new_value_dict}    New_Request
    ${data}    Parse XML    ${requests_dir}${/}New_Request.xml    keep_clark_notation=True
    ${text_name}    Evaluate Xpath    ${data}    //name
    Should be equal    ${text_name[0].text}    Carlota
    ${text_name2}    Evaluate Xpath    ${data}    //name2
    Should be equal    ${text_name2[0].text}    BBBB
    ${text_date}    Evaluate Xpath    ${data}    //startDate
    Should be equal    ${text_date[0].text}    2019-06-03
    Should be equal    ${text_date[1].text}    2019-06-03
    Should be equal    ${text_date[2].text}    2019-06-03
    ${text_reason}    Evaluate Xpath    ${data}    //Reason
    Should be equal    ${text_reason[0].text}    0000
    Should be equal    ${text_reason[1].text}    0000
    Should be equal    ${text_reason[2].text}    0000

Test Edit XML Request 8
    [Documentation]    Change all dates tags
    ${new_value_dict}    Create Dictionary    startDate=07-06-2020
    ${xml_edited}    Edit XML Request    ${requests_dir}${/}request.xml    ${new_value_dict}    New_Request
    ${data}    Parse XML    ${requests_dir}${/}New_Request.xml    keep_clark_notation=True
    ${text_name}    Evaluate Xpath    ${data}    //name
    Should be equal    ${text_name[0].text}    AAAAA
    ${text_name2}    Evaluate Xpath    ${data}    //name2
    Should be equal    ${text_name2[0].text}    BBBB
    ${text_date}    Evaluate Xpath    ${data}    //startDate
    Should be equal    ${text_date[0].text}    07-06-2020
    Should be equal    ${text_date[1].text}    07-06-2020
    Should be equal    ${text_date[2].text}    07-06-2020
    ${text_reason}    Evaluate Xpath    ${data}    //Reason
    Should be equal    ${text_reason[0].text}    0000
    Should be equal    ${text_reason[1].text}    0000
    Should be equal    ${text_reason[2].text}    0000

Test Call SOAP Method with XML Anything
    Create Soap Client    ${wsdl_calculator}
    ${response}    Call SOAP Method With XML  ${requests_dir}${/}Request_Calculator_500.xml    status=anything
    ${result}    Get Data From XML By Tag    ${response}    faultstring
    log    ${result}

Test Call SOAP Method with String XML Anything
    Create Soap Client    ${wsdl_calculator}
    ${response}    Call SOAP Method With String XML  ${request_string_500}    status=anything
    ${result}    Get Data From XML By Tag    ${response}    faultstring
    log    ${result}
