create or replace package uc_ai_utils as

  /**
  * UC AI
  * PL/SQL SDK to integrate AI capabilities into Oracle databases.
  * 
  * Licensed under the GNU Lesser General Public License v3.0
  * Copyright (c) 2025-present United Codes
  * https://www.united-codes.com
  */

  -- Custom type to replace apex_t_varchar2
  type t_varchar2 is table of varchar2(32767) index by pls_integer;

  /**
   * Split a string by delimiter (replaces apex_string.split)
   * 
   * @param p_str String to split
   * @param p_delimiter Delimiter character(s)
   * @return Table of strings
   */
  function split(
    p_str in varchar2,
    p_delimiter in varchar2 default ':'
  ) return t_varchar2;

  /**
   * Join array elements with delimiter (replaces apex_string.join)
   * 
   * @param p_table Table of strings
   * @param p_delimiter Delimiter character(s)
   * @return Joined string
   */
  function join(
    p_table in t_varchar2,
    p_delimiter in varchar2 default ','
  ) return varchar2;

  /**
   * Extract bind variables from PL/SQL code using regex (replaces apex_string.grep)
   * 
   * @param p_str String to search
   * @param p_pattern Regex pattern
   * @param p_modifier Regex modifiers (i for case-insensitive)
   * @param p_subexpression Subexpression number to extract
   * @return Table of matched strings
   */
  function grep(
    p_str in clob,
    p_pattern in varchar2,
    p_modifier in varchar2 default null,
    p_subexpression in varchar2 default null
  ) return t_varchar2;

  /**
   * Convert BLOB to Base64 CLOB (replaces apex_web_service.blob2clobbase64)
   * 
   * @param p_blob BLOB to convert
   * @return Base64 encoded CLOB
   */
  function blob2clobbase64(
    p_blob in blob
  ) return clob;

end uc_ai_utils;
/
