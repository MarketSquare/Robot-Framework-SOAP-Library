# -*- coding: utf-8 -*-
from os.path import abspath, dirname, join

try:
    from setuptools import setup
except ImportError as error:
    from distutils.core import setup


version_file = join(dirname(abspath(__file__)), 'SoapLibrary', 'version.py')

with open(version_file) as file:
    code = compile(file.read(), version_file, 'exec')
    exec(code)

setup(name             = 'robotframework-soaplibrary',
      version          = '1.3',
      description      = 'SOAP Library for Robot Framework',
	  long_description = 'Test library for Robot Framework to create automated test like using SOAPUI',
      author           = 'Altran Portugal',
      author_email     = 'samuca@gmail.com',
      license          = 'MIT License',
      url              = 'https://github.com/Altran-PT-GDC/Robot-Framework-SOAP-Library',
      packages         = ['SoapLibrary'],
      install_requires = ['robotframework', 'zeep', 'requests', 'urllib3']
      )
