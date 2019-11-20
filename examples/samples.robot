*** Settings ***
Library           SoapLibrary
Library           Collections

*** Variables ***
${wsdl_brazilian_post_office}    https://apps.correios.com.br/SigepMasterJPA/AtendeClienteService/AtendeCliente?wsdl
${wsdl_ip_geo}                   http://ws.cdyne.com/ip2geo/ip2geo.asmx?wsdl

*** Test Cases ***
Test with Convert XML Response to Dictionary
    [Documentation]    Test with 'Call SOAP Method With XML' and get the response values using ´Convert XML Response to Dictionary´
    Create SOAP Client    ${wsdl_ip_geo}
    ${response}    Call SOAP Method With XML    ${CURDIR}/request/ip.xml
    ${dict_response}    Convert XML Response to Dictionary    ${response}	
    ${body} 	Get From Dictionary    ${dict_response}    Body
    ${resolveipresponse} 	Get From Dictionary    ${body}    ResolveIPResponse
    ${resolveipresult} 	Get From Dictionary    ${ResolveIPResponse}    ResolveIPResult
    ${country}    Get From Dictionary    ${ResolveIPResult}    Country
    ${latitude}    Get From Dictionary    ${ResolveIPResult}    Latitude
    ${longitude}    Get From Dictionary    ${ResolveIPResult}    Longitude
    ${areacode}    Get From Dictionary    ${ResolveIPResult}    AreaCode
    ${certainty}    Get From Dictionary    ${ResolveIPResult}    Certainty
    ${countrycode}    Get From Dictionary    ${ResolveIPResult}    CountryCode
    Log    ${country}
    Log    ${latitude}
    Log    ${longitude}
    Log    ${areacode}
    Log    ${certainty}
    Log    ${countrycode}

Test with Get Data From XML By Tag
    [Documentation]    Test with 'Call SOAP Method With XML' and get the response values using ´Get Data From XML By Tag´
    Create SOAP Client    ${wsdl_brazilian_post_office}
    ${response}    Call SOAP Method With XML    ${CURDIR}/request/cep.xml
    ${postal_code}    Get Data From XML By Tag    ${response}    cep
    ${city}    Get Data From XML By Tag    ${response}    cidade
    ${street}    Get Data From XML By Tag    ${response}    end
    ${state}    Get Data From XML By Tag    ${response}    uf
    Log    ${postal_code}
    Log    ${city}
    Log    ${street}
    Log    ${state}