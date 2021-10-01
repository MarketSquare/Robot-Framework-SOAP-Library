from .SoapLibrary import SoapLibrary


class SoapLibrary(SoapLibrary):
    """
        SoapLibrary is a library for testing SOAP-based web services.

        SoapLibrary is based on [https://python-zeep.readthedocs.io/en/master/|Zeep], a modern SOAP client for Python.

        This library is designed for those who want to work with webservice automation as if they were using SoapUI,
        make a request through an XML file, and receive the response in another XML file.

        = Example =

        | ***** Settings *****
        | Library           SoapLibrary
        | Library           OperatingSystem
        |
        | ***** Test Cases *****
        | Example
        |     Create Soap Client    http://endpoint.com/example.asmx?wsdl
        |     ${response}    Call SOAP Method With XML    ${CURDIR}/request.xml
        |     ${text}    Get Data From XML By Tag    ${response}    tag_name
        |     Log    ${text}
        |     Save XML To File    ${response}    ${CURDIR}    response_test
        """
    def __init__(self):
        pass
