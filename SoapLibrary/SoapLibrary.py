import os
import logging.config
from .config import DICT_CONFIG
from requests import Session
from zeep import Client
from zeep.transports import Transport
from zeep.wsdl.utils import etree
from robot.api import logger
from robot.api.deco import keyword
from six import iteritems

logging.config.dictConfig(DICT_CONFIG)

DEFAULT_HEADERS = {'Content-Type': 'text/xml; charset=utf-8'}


class SoapLibrary:
    def __init__(self):
        self.client = None
        self.url = None

    @keyword("Create SOAP Client")
    def create_soap_client(self, url):
        """
        Loads a WSDL from the given URL and creates a Zeep client.
        List all Available operations/methods with INFO log level.

        *Input Arguments:*
        | *Name* | *Description* |
        | url | wsdl url |

        *Example:*
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
        """
        Send an XML file as a request to the SOAP client. The path to the Request XML file is required as argument,
        the SOAP method is inside the XML file.

        *Input Arguments:*
        | *Name* | *Description* |
        | xml | file path to xml file |
        | headers | dictionary with request headers. Default ``{'Content-Type': 'text/xml; charset=utf-8'}`` |

        *Example:*
        | ${response}= | Call SOAP Method With XML |  C:\\Request.xml |
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
        log_header_response_from_ws = '<font size="3"><b>Response from webservice:</b></font> '
        logger.info(log_header_response_from_ws, html=True)
        logger.info(etree.tostring(etree_response, pretty_print=True, encoding='unicode'))
        return etree_response

    @keyword("Get Data From XML By Tag")
    def get_data_from_xml_tag(self, xml, tag, index=1):
        """
        Gets data from XML using a given tag. If the tag returns zero or more than one result, it will show a warning.
        The xml argument must be an etree object, can be used with the return of the keyword `Call SOAP Method With XML`.

        *Input Arguments:*
        | *Name* | *Description* |
        | xml | xml etree object |
        | tag | tag to get value from |
        | index | tag index if there are multiple tags with the same name, starting at 1. Default is set to 1 |

        *Examples:*
        | ${response}= | Call SOAP Method With XML |  C:\\Request.xml |
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
        elif len(data_list) > 1:
            logger.warn('The tag you entered found %s items, returning the text in the index '
                        'number %s, if you want a different index inform the argument index=N' % (len(data_list), new_index))
        return data_list[new_index].text

    @keyword("Edit XML Request")
    def edit_xml(self, xml_file_path, new_values_dict, edited_request_name):
        """
        Changes a field on the given XML to a new given value, the values must be in a dictionary.
        xml_filepath must be a "template" of the request to the webservice.
        new_values_dict must be a dictionary with the keys and values to change.
        request_name will be the name of the new XMl file generated with the changed request.

        Returns the file path of the new Request file.

        *Input Arguments:*
        | *Name* | *Description* |
        | xml_file_path | file path to xml file |
        | new_values_dict | dictionary with tags as keys and tag value as value |
        | edited_request_name |  name of the new XMl file generated with the changed request |

        *Example*:
        | ${dict} | Create Dictionary | tag_name1=SomeText | tag_name2=OtherText |
        | ${xml_edited}= | Edit XML Request | request_filepath | ${dict} | New_Request |
        """
        string_xml = self._convert_xml_to_raw_text(xml_file_path)
        xml = self._convert_string_to_xml(string_xml)
        if not isinstance(new_values_dict, dict):
            raise Exception("new_values_dict argument must be a dictionary")
        for key, value in iteritems(new_values_dict):
            if len(xml.xpath(self._replace_xpath_by_local_name(key))) == 0:
                logger.warn('Tag "%s" not found' % key)
                continue
            xml.xpath(self._replace_xpath_by_local_name(key))[0].text = value
        # Create new file with replaced request
        new_file_path = self._save_to_file(os.path.dirname(xml_file_path), edited_request_name, etree.tostring(xml))
        return new_file_path

    @keyword("Save XML To File")
    def save_xml_to_file(self, etree_xml, save_folder, file_name):
        """
        Save the webservice response as a XML file.

        Returns the file path of the newly created xml file.

        *Input Arguments:*
        | *Name* | *Description* |
        | etree_xml | etree object of the xml |
        | save_folder | directory to save the new file |
        | file_name | name of the new xml file without .xml |

        *Example*:
        | ${response_file}= | Save XML To File |  ${response} | ${CURDIR} | response_file_name |
        """
        new_file_path = self._save_to_file(save_folder, file_name, etree.tostring(etree_xml, pretty_print=True))
        return new_file_path

    @keyword("Convert XML Response to Dictionary")
    def convert_response_dict(self, xml_etree):
        """
        Convert the webservice response into a dictionary.

        *Input Arguments:*
        | *Name* | *Description* |
        | xml_etree | etree object of the xml to convert to dictionary |

        *Example:*
        | ${dict_response}= | Convert XML Response to Dictionary | ${response} |
        """
        result = {}
        for element in xml_etree.iterchildren():
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

    @keyword("Call SOAP Method")
    def call_soap_method(self, name, *args):
        """
        If the webservice have simple SOAP method with few arguments, you can call the method with the given
        `name` and `args`

        *Input Arguments:*
        | *Name* | *Description* |
        | name | Name of the SOAP operation/method |
        | args | List of request entries |

        *Example:*
        | ${response}= | Call SOAP Method | method_name | arg1 | arg2 |
        """
        method = getattr(self.client.service, name)
        response = method(*args)
        return response

    @staticmethod
    def _convert_xml_to_raw_text(xml_file_path):
        """
        Converts a xml file into a string.

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
        """
        Parses a unicode string
        
        :param unicode_str: unicode string
        :return: parsed string
        """
        utf8_parser = etree.XMLParser(encoding='utf-8')
        string_utf8 = unicode_str.encode('utf-8')
        return etree.fromstring(string_utf8, parser=utf8_parser)

    def _parse_xpath(self, tags):
        """
        Parses a single xpath or a list of xml tags

        :param tags: string for a single xml tag or list for multiple xml tags
        :return:
        """
        xpath = ''
        if isinstance(tags, list):
            for el in tags:
                xpath += self._replace_xpath_by_local_name(el)
        else:
            xpath += self._replace_xpath_by_local_name(tags)
        return xpath

    @staticmethod
    def _convert_string_to_xml(xml_string):
        """
        Converts a given string to xml object using etree.
        
        :param xml_string: string with xml content
        :return: xml object
        """
        return etree.fromstring(xml_string)

    @staticmethod
    def _replace_xpath_by_local_name(xpath_tag):
        """
        Replaces the given xpath_tag in an xpath using name() function.
        Returns the replaced xpath .

        :param xpath_tag: tag to replace with in xpath
        :return: replaced xpath tag
        """
        local_name_xpath = "//*[name()='%s']"
        return local_name_xpath % xpath_tag

    @staticmethod
    def _save_to_file(save_folder, file_name, text):
        """
        Saves text into a new file.

        :param save_folder: folder to save the new xml file
        :param file_name: name of the new file
        :param text: file text
        :return new file path
        """
        new_file_name = "%s.xml" % file_name
        new_file_path = os.path.join(save_folder, new_file_name)
        request_file = open(new_file_path, 'wb')
        request_file.write(text)
        request_file.close()
        return new_file_path
