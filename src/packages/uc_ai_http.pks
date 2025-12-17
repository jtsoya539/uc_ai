create or replace package uc_ai_http as

  /**
  * UC AI
  * PL/SQL SDK to integrate AI capabilities into Oracle databases.
  * 
  * Licensed under the GNU Lesser General Public License v3.0
  * Copyright (c) 2025-present United Codes
  * https://www.united-codes.com
  */

  -- HTTP header record type
  type t_header is record (
    name varchar2(256),
    value varchar2(32767)
  );

  type t_headers is table of t_header index by pls_integer;

  -- Global request headers (similar to apex_web_service.g_request_headers)
  g_request_headers t_headers;

  /**
   * Clear all request headers
   */
  procedure clear_request_headers;

  /**
   * Set request headers using name/value pairs
   * 
   * @param p_name_01 First header name
   * @param p_value_01 First header value
   * @param p_name_02 Second header name (optional)
   * @param p_value_02 Second header value (optional)
   * ... up to 10 headers
   */
  procedure set_request_headers(
    p_name_01 in varchar2,
    p_value_01 in varchar2,
    p_name_02 in varchar2 default null,
    p_value_02 in varchar2 default null,
    p_name_03 in varchar2 default null,
    p_value_03 in varchar2 default null,
    p_name_04 in varchar2 default null,
    p_value_04 in varchar2 default null,
    p_name_05 in varchar2 default null,
    p_value_05 in varchar2 default null
  );

  /**
   * Make REST request (replaces apex_web_service.make_rest_request)
   * 
   * @param p_url URL to call
   * @param p_http_method HTTP method (GET, POST, PUT, DELETE, etc.)
   * @param p_body Request body (for POST/PUT)
   * @param p_credential_static_id Not used in standalone version (kept for compatibility)
   * @return Response body as CLOB
   */
  function make_rest_request(
    p_url in varchar2,
    p_http_method in varchar2 default 'GET',
    p_body in clob default null,
    p_credential_static_id in varchar2 default null
  ) return clob;

end uc_ai_http;
/
