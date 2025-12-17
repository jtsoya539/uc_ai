create or replace package body uc_ai_http as

  /**
   * Clear all request headers
   */
  procedure clear_request_headers
  is
  begin
    g_request_headers.delete;
  end clear_request_headers;

  /**
   * Set request headers using name/value pairs
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
  )
  is
    l_idx pls_integer := 1;
  begin
    if p_name_01 is not null then
      g_request_headers(l_idx).name := p_name_01;
      g_request_headers(l_idx).value := p_value_01;
      l_idx := l_idx + 1;
    end if;

    if p_name_02 is not null then
      g_request_headers(l_idx).name := p_name_02;
      g_request_headers(l_idx).value := p_value_02;
      l_idx := l_idx + 1;
    end if;

    if p_name_03 is not null then
      g_request_headers(l_idx).name := p_name_03;
      g_request_headers(l_idx).value := p_value_03;
      l_idx := l_idx + 1;
    end if;

    if p_name_04 is not null then
      g_request_headers(l_idx).name := p_name_04;
      g_request_headers(l_idx).value := p_value_04;
      l_idx := l_idx + 1;
    end if;

    if p_name_05 is not null then
      g_request_headers(l_idx).name := p_name_05;
      g_request_headers(l_idx).value := p_value_05;
    end if;
  end set_request_headers;

  /**
   * Make REST request using UTL_HTTP
   */
  function make_rest_request(
    p_url in varchar2,
    p_http_method in varchar2 default 'GET',
    p_body in clob default null,
    p_credential_static_id in varchar2 default null
  ) return clob
  is
    l_http_request utl_http.req;
    l_http_response utl_http.resp;
    l_response_text clob;
    l_buffer varchar2(32767);
    l_amount pls_integer := 32767;
    l_offset pls_integer := 1;
    l_raw_buffer raw(32767);
    l_body_length pls_integer;
  begin
    -- Initialize response CLOB
    sys.dbms_lob.createtemporary(l_response_text, true);

    -- Set wallet if needed for HTTPS
    -- Note: Users may need to configure wallet path via:
    -- utl_http.set_wallet('file:/path/to/wallet', 'wallet_password');
    
    -- Begin request
    l_http_request := utl_http.begin_request(
      url => p_url,
      method => upper(p_http_method),
      http_version => 'HTTP/1.1'
    );

    -- Set headers from global array
    if g_request_headers.count > 0 then
      for i in g_request_headers.first .. g_request_headers.last loop
        if g_request_headers.exists(i) then
          utl_http.set_header(
            r => l_http_request,
            name => g_request_headers(i).name,
            value => g_request_headers(i).value
          );
        end if;
      end loop;
    end if;

    -- Write body if provided (for POST/PUT/PATCH)
    if p_body is not null and upper(p_http_method) in ('POST', 'PUT', 'PATCH') then
      l_body_length := sys.dbms_lob.getlength(p_body);
      
      -- Set Content-Length header
      utl_http.set_header(
        r => l_http_request,
        name => 'Content-Length',
        value => to_char(l_body_length)
      );

      -- Write body in chunks
      l_offset := 1;
      while l_offset <= l_body_length loop
        l_amount := least(32767, l_body_length - l_offset + 1);
        sys.dbms_lob.read(p_body, l_amount, l_offset, l_buffer);
        utl_http.write_text(l_http_request, l_buffer);
        l_offset := l_offset + l_amount;
      end loop;
    end if;

    -- Get response
    l_http_response := utl_http.get_response(l_http_request);

    -- Read response body
    begin
      loop
        utl_http.read_text(l_http_response, l_buffer, 32767);
        sys.dbms_lob.writeappend(l_response_text, length(l_buffer), l_buffer);
      end loop;
    exception
      when utl_http.end_of_body then
        null; -- Expected exception when response is fully read
    end;

    -- End response
    utl_http.end_response(l_http_response);

    return l_response_text;

  exception
    when others then
      -- Clean up on error
      if l_http_response.status_code is not null then
        begin
          utl_http.end_response(l_http_response);
        exception
          when others then
            null;
        end;
      end if;
      raise;
  end make_rest_request;

end uc_ai_http;
/
