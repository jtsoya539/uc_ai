# UC AI Standalone Migration Guide

## Overview

The UC AI framework has been refactored to remove dependencies on Oracle APEX and the Logger framework, making it a truly standalone PL/SQL framework that can be used in any Oracle database without additional installations.

## What Changed

### Removed Dependencies

1. **Oracle APEX** - No longer required
   - `apex_web_service` → Replaced with custom `uc_ai_http` package using `UTL_HTTP`
   - `apex_t_varchar2` → Replaced with custom `uc_ai_utils.t_varchar2` type
   - `apex_string` utilities → Replaced with custom implementations in `uc_ai_utils`
   - `apex_plugin_util` → Replaced with `DBMS_SQL` for dynamic PL/SQL execution
   - `apex_debug` → Replaced with `DBMS_OUTPUT`
   - `apex_util` → Removed (was only used for APEX session management)

2. **Logger Framework** - No longer required
   - All `logger.*` calls → Replaced with `DBMS_OUTPUT` via `uc_ai_logger`

### New Packages

#### 1. `uc_ai_utils` - Utility Functions
Provides common utility functions that were previously provided by APEX:

- **`t_varchar2`** - Custom type to replace `apex_t_varchar2`
- **`split()`** - Split strings by delimiter (replaces `apex_string.split`)
- **`join()`** - Join array elements (replaces `apex_string.join`)
- **`grep()`** - Regex pattern matching (replaces `apex_string.grep`)
- **`blob2clobbase64()`** - Convert BLOB to Base64 CLOB (replaces `apex_web_service.blob2clobbase64`)

#### 2. `uc_ai_http` - HTTP Operations
Provides HTTP functionality using Oracle's built-in `UTL_HTTP`:

- **`g_request_headers`** - Global headers array (replaces `apex_web_service.g_request_headers`)
- **`clear_request_headers()`** - Clear all headers
- **`set_request_headers()`** - Set multiple headers at once
- **`make_rest_request()`** - Make HTTP requests (replaces `apex_web_service.make_rest_request`)

### Modified Packages

All provider packages have been updated to use the new utility packages:
- `uc_ai_anthropic`
- `uc_ai_google`
- `uc_ai_oci`
- `uc_ai_ollama`
- `uc_ai_openai`
- `uc_ai_tools_api`
- `uc_ai_message_api`
- `uc_ai_logger`
- `uc_ai_toon`

## Installation

### Prerequisites

1. **Oracle Database** - Version 11g or higher
2. **UTL_HTTP Access** - Required for making HTTP requests to AI providers
3. **Network ACL** - Configure network access for AI provider endpoints

### Network ACL Configuration

Before using UC AI, you must configure Oracle's Access Control List (ACL) to allow outbound HTTP/HTTPS connections:

```sql
-- Grant network access to your schema
BEGIN
  -- For Oracle 12c and above
  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
    host => '*.openai.com',
    ace  => xs$ace_type(
      privilege_list => xs$name_list('http', 'connect', 'resolve'),
      principal_name => 'YOUR_SCHEMA_NAME',
      principal_type => xs_acl.ptype_db
    )
  );
  
  -- Repeat for other AI providers
  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
    host => '*.anthropic.com',
    ace  => xs$ace_type(
      privilege_list => xs$name_list('http', 'connect', 'resolve'),
      principal_name => 'YOUR_SCHEMA_NAME',
      principal_type => xs_acl.ptype_db
    )
  );
  
  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
    host => '*.googleapis.com',
    ace  => xs$ace_type(
      privilege_list => xs$name_list('http', 'connect', 'resolve'),
      principal_name => 'YOUR_SCHEMA_NAME',
      principal_type => xs_acl.ptype_db
    )
  );
  
  -- Add other providers as needed (OCI, Ollama, xAI, OpenRouter)
END;
/
```

For Oracle 11g:
```sql
BEGIN
  DBMS_NETWORK_ACL_ADMIN.CREATE_ACL(
    acl         => 'uc_ai_acl.xml',
    description => 'ACL for UC AI HTTP access',
    principal   => 'YOUR_SCHEMA_NAME',
    is_grant    => TRUE,
    privilege   => 'connect'
  );
  
  DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE(
    acl       => 'uc_ai_acl.xml',
    principal => 'YOUR_SCHEMA_NAME',
    is_grant  => TRUE,
    privilege => 'resolve'
  );
  
  DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL(
    acl  => 'uc_ai_acl.xml',
    host => '*.openai.com'
  );
  
  -- Repeat ASSIGN_ACL for other providers
END;
/
```

### HTTPS/SSL Configuration

For HTTPS connections, you may need to configure Oracle Wallet:

```sql
-- Set wallet location (adjust path as needed)
BEGIN
  UTL_HTTP.SET_WALLET('file:/path/to/oracle/wallet', 'wallet_password');
END;
/
```

Alternatively, you can set the wallet in your session before calling UC AI functions.

### Installation Steps

1. Run the installation script:
```sql
@install_uc_ai.sql
```

2. Enable DBMS_OUTPUT for logging (in your session):
```sql
BEGIN
  uc_ai_logger.enable_dbms_output;
END;
/
```

Or use SQL*Plus/SQLcl command:
```sql
SET SERVEROUTPUT ON SIZE UNLIMITED
```

## Usage Changes

### Logging

**Before (with Logger):**
```sql
-- Logger was automatically configured
-- Logs were stored in logger_logs table
```

**After (with DBMS_OUTPUT):**
```sql
-- Enable DBMS_OUTPUT in your session
SET SERVEROUTPUT ON SIZE UNLIMITED

-- Or programmatically
BEGIN
  uc_ai_logger.enable_dbms_output(p_buffer_size => 1000000);
END;
/

-- Logs will now appear in DBMS_OUTPUT
```

### API Keys

API keys are still managed the same way using the `uc_ai_get_key` function. You need to implement this function to return your API keys securely.

Example implementation:
```sql
CREATE OR REPLACE FUNCTION uc_ai_get_key(p_provider IN VARCHAR2)
  RETURN VARCHAR2
IS
BEGIN
  CASE p_provider
    WHEN 'openai' THEN
      RETURN 'your-openai-api-key';
    WHEN 'anthropic' THEN
      RETURN 'your-anthropic-api-key';
    WHEN 'google' THEN
      RETURN 'your-google-api-key';
    -- Add other providers as needed
    ELSE
      RAISE_APPLICATION_ERROR(-20001, 'Unknown provider: ' || p_provider);
  END CASE;
END;
/
```

**Security Note:** In production, store API keys securely (e.g., in encrypted tables, Oracle Wallet, or external key management systems).

### Web Credentials

The `g_apex_web_credential` variables are still present for backward compatibility but are not used in the standalone version. All authentication is now handled via the `uc_ai_get_key` function.

## Breaking Changes

### 1. Tool Creation API

**Before:**
```sql
l_tool_id := uc_ai_tools_api.create_tool_from_schema(
  p_tool_code => 'my_tool',
  p_description => 'My tool',
  p_function_call => 'return my_function(:args);',
  p_json_schema => l_schema,
  p_tags => apex_t_varchar2('tag1', 'tag2')  -- APEX type
);
```

**After:**
```sql
DECLARE
  l_tags uc_ai_utils.t_varchar2;
BEGIN
  l_tags(1) := 'tag1';
  l_tags(2) := 'tag2';
  
  l_tool_id := uc_ai_tools_api.create_tool_from_schema(
    p_tool_code => 'my_tool',
    p_description => 'My tool',
    p_function_call => 'return my_function(:args);',
    p_json_schema => l_schema,
    p_tags => l_tags  -- Custom type
  );
END;
/
```

### 2. Tool Tags

**Before:**
```sql
uc_ai.g_tool_tags := apex_t_varchar2('tag1', 'tag2');
```

**After:**
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

### 3. Logging Output

Logs are now sent to `DBMS_OUTPUT` instead of being stored in database tables. Make sure to:
- Enable `SERVEROUTPUT` in your SQL client
- Or call `uc_ai_logger.enable_dbms_output()` programmatically

## Compatibility Notes

### Backward Compatibility

- All public APIs remain the same
- Function signatures are unchanged
- Return types are unchanged
- The framework will work exactly as before from a functional perspective

### What's NOT Backward Compatible

- Log output location (DBMS_OUTPUT vs database tables)
- Tool tag initialization syntax (array literal vs indexed assignment)
- APEX Web Credentials are ignored (use `uc_ai_get_key` instead)

## Performance Considerations

### UTL_HTTP vs APEX_WEB_SERVICE

The new `uc_ai_http` package uses `UTL_HTTP` which:
- ✅ Has similar performance to `apex_web_service`
- ✅ Supports all HTTP methods (GET, POST, PUT, DELETE, etc.)
- ✅ Handles large request/response bodies via CLOB
- ⚠️ Requires proper ACL configuration
- ⚠️ May require Oracle Wallet configuration for HTTPS

### DBMS_OUTPUT vs Logger

Using `DBMS_OUTPUT` for logging:
- ✅ No database overhead (no table writes)
- ✅ Immediate output in SQL clients
- ⚠️ Limited buffer size (default 1MB, configurable)
- ⚠️ Not persistent (logs are not stored)
- ⚠️ Session-specific (each session needs to enable output)

**Recommendation:** For production environments where you need persistent logs, consider implementing a custom logging solution or using Oracle's built-in diagnostic tools.

## Troubleshooting

### Common Issues

#### 1. ORA-29273: HTTP request failed

**Cause:** Network ACL not configured or wallet not set for HTTPS

**Solution:**
```sql
-- Check ACL configuration
SELECT * FROM dba_network_acls;
SELECT * FROM dba_network_acl_privileges;

-- Configure ACL (see Network ACL Configuration section above)
```

#### 2. ORA-24247: network access denied by access control list (ACL)

**Cause:** Your schema doesn't have permission to access the network

**Solution:** Grant network privileges (see Network ACL Configuration section)

#### 3. No log output visible

**Cause:** DBMS_OUTPUT not enabled

**Solution:**
```sql
SET SERVEROUTPUT ON SIZE UNLIMITED
-- Or
BEGIN
  uc_ai_logger.enable_dbms_output;
END;
/
```

#### 4. ORA-29024: Certificate validation failure

**Cause:** SSL certificate validation failed (HTTPS connections)

**Solution:**
```sql
-- Option 1: Configure Oracle Wallet with trusted certificates
-- Option 2: Disable SSL verification (NOT recommended for production)
BEGIN
  UTL_HTTP.SET_WALLET('');
END;
/
```

## Migration Checklist

- [ ] Remove Logger framework installation (if it was only used for UC AI)
- [ ] Remove APEX dependency (if it was only used for UC AI)
- [ ] Configure Network ACL for AI provider endpoints
- [ ] Configure Oracle Wallet for HTTPS (if needed)
- [ ] Implement `uc_ai_get_key` function for API key management
- [ ] Update tool creation code to use `uc_ai_utils.t_varchar2`
- [ ] Update tool tag initialization to use indexed assignment
- [ ] Enable DBMS_OUTPUT in your sessions/applications
- [ ] Test all AI provider integrations
- [ ] Update any custom code that relied on APEX types

## Benefits of Standalone Version

1. **No External Dependencies** - Works with vanilla Oracle Database
2. **Simpler Installation** - No need to install APEX or Logger
3. **Broader Compatibility** - Works in any Oracle environment (11g+)
4. **Easier Deployment** - Single framework installation
5. **Better Portability** - Move between databases without dependency concerns

## Support

For issues or questions:
- GitHub: https://github.com/United-Codes/uc_ai
- Documentation: https://www.united-codes.com/products/uc-ai/docs/
- Community: https://github.com/United-Codes/uc_ai/discussions

## License

UC AI is licensed under the GNU Lesser General Public License v3.0
Copyright (c) 2025-present United Codes
