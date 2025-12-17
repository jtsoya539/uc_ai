create or replace package body uc_ai_logger as

  /**
   * Convert parameters to string for logging
   */
  function params_to_string(p_params in tab_param)
    return varchar2
  is
    l_result varchar2(32767 char);
  begin
    if p_params.count > 0 then
      <<params_loop>>
      for i in 1 .. p_params.count loop
        if l_result is not null then
          l_result := l_result || ', ';
        end if;
        l_result := l_result || p_params(i).name || '=' || p_params(i).val;
      end loop params_loop;
      return ' [' || l_result || ']';
    end if;
    return null;
  end params_to_string;

  /**
   * Build full message with scope, extra, and params
   */
  function build_message(
    p_text in varchar2,
    p_scope in varchar2,
    p_extra in clob,
    p_params in tab_param)
    return clob
  is
    l_message clob;
  begin
    l_message := p_text;
    
    if p_scope is not null then
      l_message := '[' || p_scope || '] ' || l_message;
    end if;
    
    if p_params.count > 0 then
      l_message := l_message || params_to_string(p_params);
    end if;

    if p_extra is not null then
      l_message := l_message || ' | Extra: ' || p_extra;
    end if;

    return l_message;
  end build_message;

  /**
   * Internal logging procedure using DBMS_OUTPUT
   *
   * @param p_level Log level: ERROR, WARNING, INFO, DEBUG
   * @param p_text Message text
   * @param p_scope Scope/context
   * @param p_extra Additional information
   * @param p_params Array of parameters
   */
  procedure log_internal(
    p_level in varchar2,
    p_text in varchar2,
    p_scope in varchar2,
    p_extra in clob,
    p_params in tab_param)
  is
    l_message clob;
    l_prefix varchar2(20);
  begin
    -- Build the complete message
    l_message := build_message(
      p_text => p_text,
      p_scope => p_scope,
      p_extra => p_extra,
      p_params => p_params);
    
    -- Add level prefix
    l_prefix := '[' || upper(p_level) || '] ';
    l_message := l_prefix || l_message;
    
    -- Log in chunks of max 32767 characters (DBMS_OUTPUT limit)
    declare
      c_max_chunk_size constant pls_integer := 32767;
      c_indicator_overhead constant pls_integer := 20; -- Reserve space for "[999/999] " indicator
      l_message_length pls_integer;
      l_offset pls_integer := 1;
      l_chunk varchar2(32767 char);
      l_chunk_num pls_integer := 1;
      l_total_chunks pls_integer;
      l_actual_chunk_size pls_integer;
      l_indicator varchar2(20 char);
    begin
      l_message_length := length(l_message);
      
      -- Calculate if we need to split and adjust chunk size accordingly
      if l_message_length > c_max_chunk_size then
        l_actual_chunk_size := c_max_chunk_size - c_indicator_overhead;
        l_total_chunks := ceil(l_message_length / l_actual_chunk_size);
      else
        l_actual_chunk_size := c_max_chunk_size;
        l_total_chunks := 1;
      end if;
      
      while l_offset <= l_message_length loop
        l_chunk := substr(l_message, l_offset, l_actual_chunk_size);
        
        -- Add chunk indicator if message is split
        if l_total_chunks > 1 then
          l_indicator := '[' || l_chunk_num || '/' || l_total_chunks || '] ';
          l_chunk := l_indicator || l_chunk;
        end if;
        
        -- Output to DBMS_OUTPUT
        sys.dbms_output.put_line(l_chunk);
        
        l_offset := l_offset + l_actual_chunk_size;
        l_chunk_num := l_chunk_num + 1;
      end loop;
    end;
  end log_internal;

  /**
   * Log error message
   */
  procedure log_error(
    p_text in varchar2 default null,
    p_scope in varchar2 default null,
    p_extra in clob default null,
    p_params in tab_param default uc_ai_logger.gc_empty_tab_param)
  is
  begin
    log_internal(
      p_level => 'ERROR',
      p_text => nvl(p_text, 'Error occurred'),
      p_scope => p_scope,
      p_extra => p_extra,
      p_params => p_params);
  end log_error;

  /**
   * Log warning message
   */
  procedure log_warning(
    p_text in varchar2,
    p_scope in varchar2 default null,
    p_extra in clob default null,
    p_params in tab_param default uc_ai_logger.gc_empty_tab_param)
  is
  begin
    log_internal(
      p_level => 'WARNING',
      p_text => p_text,
      p_scope => p_scope,
      p_extra => p_extra,
      p_params => p_params);
  end log_warning;

  /**
   * Log warning message (alias)
   */
  procedure log_warn(
    p_text in varchar2,
    p_scope in varchar2 default null,
    p_extra in clob default null,
    p_params in tab_param default uc_ai_logger.gc_empty_tab_param)
  is
  begin
    log_warning(
      p_text => p_text,
      p_scope => p_scope,
      p_extra => p_extra,
      p_params => p_params);
  end log_warn;

  /**
   * Log info message
   */
  procedure log_info(
    p_text in varchar2,
    p_scope in varchar2 default null,
    p_extra in clob default null,
    p_params in tab_param default uc_ai_logger.gc_empty_tab_param)
  is
  begin
    log_internal(
      p_level => 'INFO',
      p_text => p_text,
      p_scope => p_scope,
      p_extra => p_extra,
      p_params => p_params);
  end log_info;

  /**
   * Log debug message
   */
  procedure log(
    p_text in varchar2,
    p_scope in varchar2 default null,
    p_extra in clob default null,
    p_params in tab_param default uc_ai_logger.gc_empty_tab_param)
  is
  begin
    log_internal(
      p_level => 'DEBUG',
      p_text => p_text,
      p_scope => p_scope,
      p_extra => p_extra,
      p_params => p_params);
  end log;

  procedure enable_dbms_output(p_buffer_size in integer default 1000000)
  as
  begin
    -- Enable DBMS_OUTPUT with specified buffer size
    -- Default is 1MB which should be sufficient for most logging needs
    sys.dbms_output.enable(p_buffer_size);
  end enable_dbms_output;

end uc_ai_logger;
/
