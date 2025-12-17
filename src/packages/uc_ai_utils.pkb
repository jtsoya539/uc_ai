create or replace package body uc_ai_utils as

  /**
   * Split a string by delimiter
   */
  function split(
    p_str in varchar2,
    p_delimiter in varchar2 default ':'
  ) return t_varchar2
  is
    l_result t_varchar2;
    l_str varchar2(32767) := p_str;
    l_pos pls_integer;
    l_idx pls_integer := 1;
  begin
    if p_str is null then
      return l_result;
    end if;

    loop
      l_pos := instr(l_str, p_delimiter);
      
      if l_pos > 0 then
        l_result(l_idx) := substr(l_str, 1, l_pos - 1);
        l_str := substr(l_str, l_pos + length(p_delimiter));
        l_idx := l_idx + 1;
      else
        l_result(l_idx) := l_str;
        exit;
      end if;
    end loop;

    return l_result;
  end split;

  /**
   * Join array elements with delimiter
   */
  function join(
    p_table in t_varchar2,
    p_delimiter in varchar2 default ','
  ) return varchar2
  is
    l_result varchar2(32767);
    l_idx pls_integer;
  begin
    if p_table.count = 0 then
      return null;
    end if;

    l_idx := p_table.first;
    while l_idx is not null loop
      if l_result is not null then
        l_result := l_result || p_delimiter;
      end if;
      l_result := l_result || p_table(l_idx);
      l_idx := p_table.next(l_idx);
    end loop;

    return l_result;
  end join;

  /**
   * Extract bind variables from PL/SQL code using regex
   */
  function grep(
    p_str in clob,
    p_pattern in varchar2,
    p_modifier in varchar2 default null,
    p_subexpression in varchar2 default null
  ) return t_varchar2
  is
    l_result t_varchar2;
    l_pos pls_integer := 1;
    l_match varchar2(32767);
    l_idx pls_integer := 1;
    l_flags varchar2(10) := p_modifier;
  begin
    if p_str is null or p_pattern is null then
      return l_result;
    end if;

    -- Use REGEXP_SUBSTR to find all matches
    loop
      l_match := regexp_substr(
        p_str,
        p_pattern,
        l_pos,
        1,
        l_flags,
        nvl(to_number(p_subexpression), 0)
      );
      
      exit when l_match is null;
      
      l_result(l_idx) := l_match;
      l_idx := l_idx + 1;
      
      -- Move position forward
      l_pos := regexp_instr(
        p_str,
        p_pattern,
        l_pos,
        1,
        1,
        l_flags
      );
      
      exit when l_pos = 0;
    end loop;

    return l_result;
  end grep;

  /**
   * Convert BLOB to Base64 CLOB
   */
  function blob2clobbase64(
    p_blob in blob
  ) return clob
  is
    l_clob clob;
    l_step pls_integer := 12000; -- Must be divisible by 3 for base64
    l_offset pls_integer := 1;
    l_amount pls_integer;
    l_raw raw(32767);
    l_base64_chunk varchar2(32767);
  begin
    if p_blob is null then
      return null;
    end if;

    sys.dbms_lob.createtemporary(l_clob, true);

    while l_offset <= sys.dbms_lob.getlength(p_blob) loop
      l_amount := least(l_step, sys.dbms_lob.getlength(p_blob) - l_offset + 1);
      
      sys.dbms_lob.read(p_blob, l_amount, l_offset, l_raw);
      
      l_base64_chunk := utl_raw.cast_to_varchar2(utl_encode.base64_encode(l_raw));
      
      sys.dbms_lob.writeappend(l_clob, length(l_base64_chunk), l_base64_chunk);
      
      l_offset := l_offset + l_amount;
    end loop;

    return l_clob;
  end blob2clobbase64;

end uc_ai_utils;
/
