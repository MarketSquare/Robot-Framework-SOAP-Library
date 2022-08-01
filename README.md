[![PyPi downloads](https://img.shields.io/pypi/dm/robotframework-soaplibrary.svg)](https://pypi.org/project/robotframework-soaplibrary)
[![Total downloads](https://static.pepy.tech/personalized-badge/robotframework-soaplibrary?period=total&units=international_system&left_color=lightgrey&right_color=yellow&left_text=Total)](https://pypi.org/project/robotframework-soaplibrary)
[![Latest Version](https://img.shields.io/pypi/v/robotframework-soaplibrary.svg)](https://pypi.org/project/robotframework-soaplibrary)
[![Tests](https://github.com/Altran-PT-GDC/Robot-Framework-SOAP-Library/actions/workflows/python-app.yml/badge.svg?branch=master)](https://github.com/Altran-PT-GDC/Robot-Framework-SOAP-Library/actions/workflows/python-app.yml)


# Robot-Framework-SOAP-Library
SOAP Library for Robot Framework

## Compatibility
- _Python 3.7 +_
- _Zeep 3.1.0 +_ 

## Introduction
The SoapLibrary was created for those who want to use the Robot Framework as if they were using SoapUI, just send the request XML and get the response XML.

![alt text](https://github.com/Altran-PT-GDC/Robot-Framework-SOAP-Library/blob/master/Doc/img_SoapUI.png)

![alt text](https://github.com/Altran-PT-GDC/Robot-Framework-SOAP-Library/blob/master/Doc/img2_SoapLibrary.png)

## Instalation
For the first time install:
```commandline
pip install robotframework-soaplibrary
```
Or you can upgrade with:
```commandline
pip install --upgrade robotframework-soaplibrary
```

## Example

```RobotFramework
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
```
        
## Example with certificate

You can see [here](https://michaelhallik.github.io/blog/2022/04/10/Using-OpenSSL-to-provide-the-RF-SoapLibrary-with-a-TLS-client-certificate) an example of how to use OPENSSL to access a webservice with TLS certificate. (Thanks Michael Hallik)

## Keyword Documentation

You can find the keywords documentation [here](https://raw.githack.com/Altran-PT-GDC/Robot-Framework-SOAP-Library/master/Doc/SoapLibrary.html)     

## Authors
   - **Altran -** [Altran Web Site](https://www.altran.com/us/en/)
   - **Samuel Cabral**
   - **Joao Gomes**
   
## License
This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/Altran-PT-GDC/Robot-Framework-SOAP-Library/blob/master/LICENSE.md) file for details.   
