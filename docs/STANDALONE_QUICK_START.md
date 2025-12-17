# UC AI Standalone - Quick Start Guide

## Installation

### 1. Install UC AI Framework

```sql
@install_uc_ai.sql
```

### 2. Configure Network Access (Required)

Grant your schema permission to make HTTP requests to AI providers:

```sql
-- For Oracle 12c and above
BEGIN
  -- OpenAI
  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
    host => '*.openai.com',
    ace  => xs$ace_type(
      privilege_list => xs$name_list('http', 'connect', 'resolve'),
      principal_name => 'YOUR_SCHEMA_NAME',
      principal_type => xs_acl.ptype_db
    )
  );
  
  -- Anthropic
  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
    host => '*.anthropic.com',
    ace  => xs$ace_type(
      privilege_list => xs$name_list('http', 'connect', 'resolve'),
      principal_name => 'YOUR_SCHEMA_NAME',
      principal_type => xs_acl.ptype_db
    )
  );
  
  -- Google
  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
    host => '*.googleapis.com',
    ace  => xs$ace_type(
      privilege_list => xs$name_list('http', 'connect', 'resolve'),
      principal_name => 'YOUR_SCHEMA_NAME',
      principal_type => xs_acl.ptype_db
    )
  );
  
  -- Add other providers as needed
END;
/
```

### 3. Implement API Key Function

Create a function to securely return your API keys:

```sql
CREATE OR REPLACE FUNCTION uc_ai_get_key(p_provider IN VARCHAR2)
  RETURN VARCHAR2
IS
BEGIN
  CASE p_provider
    WHEN 'openai' THEN
      RETURN 'sk-your-openai-key-here';
    WHEN 'anthropic' THEN
      RETURN 'sk-ant-your-anthropic-key-here';
    WHEN 'google' THEN
      RETURN 'your-google-api-key-here';
    WHEN 'oci' THEN
      RETURN NULL; -- OCI uses different auth
    WHEN 'ollama' THEN
      RETURN NULL; -- Ollama typically doesn't need auth
    WHEN 'xai' THEN
      RETURN 'xai-your-key-here';
    WHEN 'openrouter' THEN
      RETURN 'sk-or-your-openrouter-key-here';
    ELSE
      RAISE_APPLICATION_ERROR(-20001, 'Unknown provider: ' || p_provider);
  END CASE;
END;
/
```

**⚠️ Security Warning:** The above is for testing only. In production, store API keys securely using:
- Encrypted database tables
- Oracle Wallet
- External key management systems
- Environment variables (via external procedures)

### 4. Enable Logging (Optional)

```sql
-- In SQL*Plus or SQLcl
SET SERVEROUTPUT ON SIZE UNLIMITED

-- Or programmatically
BEGIN
  uc_ai_logger.enable_dbms_output(p_buffer_size => 1000000);
END;
/
```

## Basic Usage

### Simple Text Generation

```sql
DECLARE
  l_result JSON_OBJECT_T;
BEGIN
  -- Enable logging to see what's happening
  uc_ai_logger.enable_dbms_output;
  
  -- Generate text
  l_result := uc_ai.generate_text(
    p_user_prompt => 'What is the capital of France?',
    p_provider => uc_ai.c_provider_openai,
    p_model => uc_ai_openai.c_model_gpt_4o_mini
  );
  
  -- Display result
  DBMS_OUTPUT.PUT_LINE('Response: ' || l_result.get_string('final_message'));
END;
/
```

### With System Prompt

```sql
DECLARE
  l_result JSON_OBJECT_T;
BEGIN
  l_result := uc_ai.generate_text(
    p_user_prompt => 'Explain quantum computing',
    p_system_prompt => 'You are a helpful physics teacher. Explain concepts simply.',
    p_provider => uc_ai.c_provider_anthropic,
    p_model => uc_ai_anthropic.c_model_claude_3_5_sonnet
  );
  
  DBMS_OUTPUT.PUT_LINE(l_result.get_string('final_message'));
END;
/
```

### Using Tools (Function Calling)

```sql
DECLARE
  l_result JSON_OBJECT_T;
  l_messages JSON_ARRAY_T;
BEGIN
  -- Enable tools
  uc_ai.g_enable_tools := TRUE;
  
  -- Create messages
  l_messages := JSON_ARRAY_T();
  l_messages.append(uc_ai_message_api.create_simple_user_message(
    'What is the weather in Paris?'
  ));
  
  -- Generate with tools
  l_result := uc_ai.generate_text(
    p_messages => l_messages,
    p_provider => uc_ai.c_provider_openai,
    p_model => uc_ai_openai.c_model_gpt_4o
  );
  
  DBMS_OUTPUT.PUT_LINE('Result: ' || l_result.get_string('final_message'));
  DBMS_OUTPUT.PUT_LINE('Tool calls: ' || l_result.get_number('tool_calls_count'));
END;
/
```

### Structured Output

```sql
DECLARE
  l_result JSON_OBJECT_T;
  l_schema JSON_OBJECT_T;
BEGIN
  -- Define output schema
  l_schema := JSON_OBJECT_T('{
    "type": "object",
    "properties": {
      "name": {"type": "string"},
      "age": {"type": "integer"},
      "city": {"type": "string"}
    },
    "required": ["name", "age", "city"]
  }');
  
  -- Generate with schema
  l_result := uc_ai.generate_text(
    p_user_prompt => 'Extract: John is 30 years old and lives in Paris',
    p_provider => uc_ai.c_provider_openai,
    p_model => uc_ai_openai.c_model_gpt_4o,
    p_response_json_schema => l_schema
  );
  
  DBMS_OUTPUT.PUT_LINE('Structured output: ' || l_result.get_string('final_message'));
END;
/
```

## Key Differences from APEX Version

### 1. Logging

**APEX Version:**
- Logs stored in `logger_logs` table or APEX debug
- Persistent across sessions
- Queryable via SQL

**Standalone Version:**
- Logs output to `DBMS_OUTPUT`
- Session-specific
- Not persistent
- Must enable `SERVEROUTPUT` to see logs

### 2. Tool Tags

**APEX Version:**
```sql
uc_ai.g_tool_tags := apex_t_varchar2('tag1', 'tag2');
```

**Standalone Version:**
```sql
DECLARE
  l_tags uc_ai_utils.t_varchar2;
BEGIN
  l_tags(1) := 'tag1';
  l_tags(2) := 'tag2';
  uc_ai.g_tool_tags := l_tags;
END;
/
```

### 3. HTTP Configuration

**APEX Version:**
- Used APEX Web Credentials for authentication
- Automatic SSL/TLS handling

**Standalone Version:**
- Uses `uc_ai_get_key()` function for API keys
- May require Oracle Wallet configuration for HTTPS
- Requires Network ACL configuration

## Troubleshooting

### "ORA-29273: HTTP request failed"

**Solution:** Configure Network ACL (see step 2 above)

### "ORA-24247: network access denied by access control list (ACL)"

**Solution:** Grant network privileges to your schema

### "No output visible"

**Solution:** Enable SERVEROUTPUT:
```sql
SET SERVEROUTPUT ON SIZE UNLIMITED
```

### "ORA-29024: Certificate validation failure"

**Solution:** Configure Oracle Wallet for SSL:
```sql
BEGIN
  UTL_HTTP.SET_WALLET('file:/path/to/wallet', 'password');
END;
/
```

## Performance Tips

1. **Reuse Connections:** The framework handles connection pooling internally
2. **Buffer Size:** Increase DBMS_OUTPUT buffer for verbose logging
3. **Network ACL:** Configure ACL once per database, not per session
4. **API Keys:** Cache keys in memory if using external key management

## Support

- Documentation: https://www.united-codes.com/products/uc-ai/docs/
- GitHub: https://github.com/United-Codes/uc_ai
- Issues: https://github.com/United-Codes/uc_ai/issues
