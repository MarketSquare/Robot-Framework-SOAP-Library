# Robot-Framework-SOAP-Library
SOAP Library for Robot Framework

## Compatibility
- _Python 2.7_
- _Python 3.7_
- _Zeep 3.1.0_ (or higher)

## Introduction
The SoapLibrary was created for those who want to use the Robot Framework as if they were using SoapUI, just send the request XML and get the response XML.

![alt text](https://github.com/Altran-PT-GDC/Robot-Framework-SOAP-Library/blob/master/Doc/img_SoapUI.png)

![alt text](https://github.com/Altran-PT-GDC/Robot-Framework-SOAP-Library/blob/master/Doc/img_SoapLibrary.png)

## Instalation
These packages are prerequisites for the library:  
`pip install zeep`  
`pip install six`  
`pip install requests`

Then: `pip install robotframework-soaplibrary`

## Example

    *** Settings ***
    Library           SoapLibrary
    Library           OperatingSystem

    *** Test Cases ***
    Example
        Create Soap Client    http://endpoint.com/example.asmx?wsdl
        ${response}    Call SOAP Method With XML    ${CURDIR}/request.xml
        ${text}    Get Data From XML By Tag    ${response}    tag_name
        Log    ${text}
        Save XML To File    ${response}    ${CURDIR}    response_test
        
## Keyword Documentation

You can find the keywords documentation [here](https://raw.githack.com/Altran-PT-GDC/Robot-Framework-SOAP-Library/master/Doc/SoapLibrary.html)     

## Authors
   - **Altran -** [Altran Web Site](https://www.altran.com/us/en/)
   - **Samuel Cabral**
   - **Joao Gomes**
   
## License
This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/Altran-PT-GDC/Robot-Framework-SOAP-Library/blob/master/LICENSE.md) file for details.   
