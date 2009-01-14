CountryCodes
============

This plugin provides an easy to access collection of ISO 3166-1, codes for the representation of names of countries and their subdivisions.
Contains the following from ISO 3166-1:
  
  * ISO 3166-1 alpha-2, a two-letter system, used in many applications, most prominently for
    country code top-level domains (ccTLDs), with some exceptions.
    
  * ISO 3166-1 alpha-3, a three-letter system, which allows a better visual association between
    country name and code element than the alpha-2 code.
    
  * ISO 3166-1 numeric, a three-digit numerical system, with the advantage of script (writing system)
    independence, and hence useful for people or systems which uses a non-Latin script. This is
    identicalto codes defined by the United Nations Statistics Division.



Example
=======

Find a country by name and retrieve information about it (alpha-2, alpha-3 and numeric):

  australia = CountryCodes.find_by_name('Australia')
  australia[:name]     # yields 'Australia'
  australia[:a2]       # yields 'au'
  australia[:a3]       # yields 'aus'
  australia[:numeric]  # yields 36
  
  
Likewise countries can be found using any of the provides attributes (name, a2, a3 or numeric), such as:

  CountryCodes.find_by_a2['au'][:name]  # yields 'Australia'


Search conditions are case-insensitive.



Copyright (c) 2007 James Brooks (http://blog.whitet.net), released under the MIT license
