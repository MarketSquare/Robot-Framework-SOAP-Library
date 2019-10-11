import os
import logging.config
from config import DICT_CONFIG
from requests import Session
from zeep import Client
from zeep.transports import Transport
from zeep.wsdl.utils import etree
from robot.api import logger
from robot.api.deco import keyword

logging.config.dictConfig(DICT_CONFIG)

DEFAULT_HEADERS = {'Content-Type': 'text/xml; charset=utf-8'}
LOG_HEADER_RESPONSE_FROM_WS = '<font size="3"><b>Response from webservice:</b></font> '
LOCAL_NAME_XPATH = "//*[name()='%s']"


class SoapLibrary:
    def __init__(self):
        self.client = None
        self.url = None

    @keyword("Create SOAP Client")
    def create_soap_client(self, url):
        """ Loads a WSDL from the given URL and creates a Zeep client.
            List all Available operations/methods:

            Example:
                | Create SOAP Client | Hostname?wsdl |
        """
        self.url = url
        session = Session()
        self.client = Client(self.url, transport=Transport(session=session))
        logger.info('Connected to: %s' % self.client.wsdl.location)
        info = self.client.service.__dict__
        operations = info["_operations"]
        logger.info('Available operations: %s' % operations.keys())

    @keyword("Call SOAP Method With XML")
    def call_soap_method_xml(self, xml, headers=DEFAULT_HEADERS):
        """ Send the informed XML to the SOAP client. You only need to inform the path to the Request XML, the SOAP
            method are inside the XML file.

            Example:
                | ${response} | Call SOAP Method With XML |  C:\\Request.xml |
        """
        # TODO check with different headers: 'SOAPAction': self.url + '/%s' % method}
        raw_text_xml = self._convert_xml_to_raw_text(xml)
        xml_obj = etree.fromstring(raw_text_xml)
        response = self.client.transport.post_xml(address=self.url, envelope=xml_obj, headers=headers)
        etree_response = self._parse_from_unicode(response.text)
        status_code = response.status_code
        if status_code != 200:
            logger.debug('URL: %s' % response.url)
            logger.debug(etree.tostring(etree_response, pretty_print=True, encoding='unicode'))
            raise AssertionError('Request Error! Status Code: %s! Reason: %s' % (status_code, response.reason))
        logger.info(LOG_HEADER_RESPONSE_FROM_WS, html=True)
        logger.info(etree.tostring(etree_response, pretty_print=True, encoding='unicode'))
        return etree_response

    @keyword("Get Data From XML By Tag")
    def get_data_from_xml_tag(self, xml, tag, index=1):
        """ Gets data from XML using a given tag. If the tag returns zero or more than one result, it will show
            an warning.

            The xml must be the return of the `Call SOAP Method With XML`

            Example:
                | ${response} | Call SOAP Method With XML |  C:\\Request.xml |
                | Get Data From XML By Tag |  ${response} | SomeTag |
                | Get Data From XML By Tag |  ${response} | SomeTag | index=9 |
        """
        new_index = index - 1
        xpath = self._parse_xpath(tag)
        data_list = xml.xpath(xpath)
        if isinstance(data_list, (float, int)):
            return int(data_list)
        if len(data_list) == 0:
            logger.warn('The search "%s" did not return any result! Please confirm the tag!' % xpath)
        if len(data_list) > 1:
            logger.warn('The tag you entered found %s items, returning the text in the index '
                        'number %s, if you want a different index inform the argument index=N' % (len(data_list), new_index))
        return data_list[new_index].text

    @keyword("Edit XML Request")
    def edit_xml(self, xml_file_path, new_values_dict, request_name):
        """ Changes a field on the given XML to a new given value, the values must be in a dictionary.
            xml_filepath must be a "template" of the request to the webservice.
            new_values_dict must be a dictionary with the keys and values to change.
            request_name will be the name of the new XMl file generated with the changed request.

            Returns the file path of the new Request file.

            Example:
                | ${dict} | Create Dictionary | someKey=someValue | someOtherKey=someOtherValue |
                | ${xml_edited} | Edit XML Request | request_filepath | ${dict} | New_Request |
                | ${response} | Call SOAP Method With XML | ${xml_edited} |
        """
        string_xml = self._convert_xml_to_raw_text(xml_file_path)
        xml = self._convert_string_to_xml(string_xml)
        if not isinstance(new_values_dict, dict):
            raise Exception("new_values_dict argument must be a dictionary")
        for key, value in new_values_dict.iteritems():
            if len(xml.xpath(LOCAL_NAME_XPATH % key)) == 0:
                logger.warn('Tag "%s" not found' % key)
                continue
            xml.xpath(LOCAL_NAME_XPATH % key)[0].text = value
        # Create new file with replaced request
        new_file_name = str(request_name) + ".xml"
        new_file_path = os.path.join(os.path.dirname(xml_file_path), new_file_name)
        request_file = open(new_file_path, 'wb')
        request_file.write(etree.tostring(xml))
        request_file.close()
        return new_file_path

    @keyword("Save XML Response File")
    def save_xml_response_file(self, response, save_folder, response_name):
        """ Save the webservice response as a XML file.

            Returns the file path of the new Request file.

            Example:
                | ${response_file} | Save XML Response File |  ${response} | Response_file |
        """
        new_file_name = str(response_name) + ".xml"
        new_file_path = os.path.join(save_folder, new_file_name)
        request_file = open(new_file_path, 'wb')
        # TODO Fix the encoding in the generated file
        request_file.write(etree.tostring(response, pretty_print=True))
        request_file.close()
        return new_file_path

    @keyword("Convert XML Response to Dictionary")
    def convert_response_dict(self, node):
        """ Convert the webservice response into a dictionary.

            Example:
                | ${response} | Call SOAP Method With XML |  C:\\Request.xml |
                | ${dict_response} | Convert XML Response to Dictionary | ${response} |
        """
        result = {}
        for element in node.iterchildren():
            # Remove namespace prefix
            key = element.tag.split('}')[1] if '}' in element.tag else element.tag
            # Process element as tree element if the inner XML contains non-whitespace content
            if element.text and element.text.strip():
                value = element.text
            else:
                value = self.convert_response_dict(element)
            if key in result:
                if type(result[key]) is list:
                    result[key].append(value)
                else:
                    tempvalue = result[key].copy()
                    result[key] = [tempvalue, value]
            else:
                result[key] = value
        return result

    @staticmethod
    def _convert_xml_to_raw_text(xml_file_path):
        """ Converts a xml file into a string.

            :param xml_file_path: xml file path
            :return: string with xml content
        """
        file_content = open(xml_file_path, 'r')
        xml = ''
        for line in file_content:
            xml += line
        file_content.close()
        return xml

    @staticmethod
    def _parse_from_unicode(unicode_str):
        """ Parses a unicode string
        
            :param unicode_str: unicode string
            :return: parsed string
        """
        utf8_parser = etree.XMLParser(encoding='utf-8')
        string_utf8 = unicode_str.encode('utf-8')
        return etree.fromstring(string_utf8, parser=utf8_parser)

    @staticmethod
    def _parse_xpath(xpath_list):
        xpath = ''
        if isinstance(xpath_list, list):
            for el in xpath_list:
                xpath += LOCAL_NAME_XPATH % el
        else:
            xpath += LOCAL_NAME_XPATH % xpath_list
        return xpath

    @staticmethod
    def _convert_string_to_xml(xml_string):
        """ Converts a given string to xml object using etree
        
            :param xml_string: string with xml content
            :return: xml object
        """
        xml = etree.fromstring(xml_string)
        return xml
