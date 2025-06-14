# Security Configuration Guide

## Overview

This document outlines the security improvements made to the Bedrock Chat application to eliminate hardcoded credentials and implement secure environment variable configuration.

## ⚠️ Critical Security Issues Resolved

The following security vulnerabilities have been addressed:

1. **Hardcoded API Tokens**: Removed hardcoded LiteLLM API tokens from source code
2. **Hardcoded Gateway URLs**: Moved gateway URLs to environment variables
3. **Credential Exposure**: Eliminated risk of credential exposure in version control

## Required Environment Variables

### LiteLLM Proxy Configuration

The application now requires the following environment variables to be set:

```bash
# LiteLLM Gateway URL - Replace with your actual gateway domain + '/bedrock' suffix
LITELLM_PROXY_GATEWAY_URL=https://your-gateway-domain.cloudfront.net/bedrock

# LiteLLM API Token - Generate this from your LiteLLM admin UI  
LITELLM_PROXY_API_TOKEN=sk-your-generated-api-token-here
```

### AWS Bedrock Configuration

```bash
# AWS Region for Bedrock services (optional, default: us-east-1)
BEDROCK_REGION=us-east-1

# Enable cross-region inference for Bedrock (optional, default: false)
ENABLE_BEDROCK_CROSS_REGION_INFERENCE=false
```

## Setup Instructions

### 1. Create Environment File

Create a `.env` file in your application root with the required variables:

```bash
# Copy and modify this template
LITELLM_PROXY_GATEWAY_URL=https://d3qyoa2hy59ns9.cloudfront.net/bedrock
LITELLM_PROXY_API_TOKEN=sk-9o-BUTRDRr93AxvPpva17w
BEDROCK_REGION=us-east-1
ENABLE_BEDROCK_CROSS_REGION_INFERENCE=false
```

### 2. Secure Your Credentials

- **Never commit `.env` files to version control**
- Add `.env` to your `.gitignore` file
- Use strong, unique API tokens
- Rotate credentials regularly

### 3. Production Deployment

For production environments, consider using:

- **AWS Secrets Manager** for credential storage
- **AWS Systems Manager Parameter Store** for configuration
- **Environment variables** in your deployment platform
- **Kubernetes Secrets** if using Kubernetes

## Code Changes Made

### Environment Variable Loading

Added secure environment variable configuration in `backend/app/bedrock.py`:

```python
# LiteLLM Proxy Configuration - secure environment variables
LITELLM_PROXY_GATEWAY_URL = os.environ.get("LITELLM_PROXY_GATEWAY_URL")
LITELLM_PROXY_API_TOKEN = os.environ.get("LITELLM_PROXY_API_TOKEN")
```

### Secure Client Factory

Created a secure client factory function with validation:

```python
def _get_secure_proxy_client():
    """
    Create a secure bedrock runtime proxy client with environment variable validation.
    
    Returns:
        Configured bedrock runtime client
        
    Raises:
        ValueError: If required environment variables are not set
    """
    if not LITELLM_PROXY_GATEWAY_URL:
        raise ValueError(
            "LITELLM_PROXY_GATEWAY_URL environment variable must be set. "
            "Please set it to your LiteLLM gateway URL with '/bedrock' suffix."
        )
    
    if not LITELLM_PROXY_API_TOKEN:
        raise ValueError(
            "LITELLM_PROXY_API_TOKEN environment variable must be set. "
            "Please set it to your LiteLLM API token generated from the admin UI."
        )
    
    from app.utils import get_proxy_bedrock_runtime
    
    return get_proxy_bedrock_runtime(
        gateway_url=LITELLM_PROXY_GATEWAY_URL,
        gateway_token=LITELLM_PROXY_API_TOKEN,
    )
```

### Updated Client Usage

Replaced hardcoded credentials in both `bedrock.py` and `stream.py`:

```python
# Before (INSECURE):
client = get_proxy_bedrock_runtime(
    gateway_url="https://d3qyoa2hy59ns9.cloudfront.net/bedrock",
    gateway_token="sk-9o-BUTRDRr93AxvPpva17w",
)

# After (SECURE):
client = _get_secure_proxy_client()
```

## Security Best Practices

1. **Environment Variables**: Use environment variables for all sensitive configuration
2. **Principle of Least Privilege**: Limit token permissions to minimum necessary
3. **Credential Rotation**: Rotate API tokens regularly
4. **Monitoring**: Monitor usage and access logs
5. **HTTPS Only**: Always use HTTPS endpoints
6. **Secret Management**: Use dedicated secret management systems in production
7. **Never Log Secrets**: Ensure secrets are never logged or displayed

## Error Handling

The application now provides clear error messages when environment variables are missing:

```
ValueError: LITELLM_PROXY_GATEWAY_URL environment variable must be set. 
Please set it to your LiteLLM gateway URL with '/bedrock' suffix.
```

```  
ValueError: LITELLM_PROXY_API_TOKEN environment variable must be set. 
Please set it to your LiteLLM API token generated from the admin UI.
```

## Validation

To verify your configuration is working:

1. Set the required environment variables
2. Start your application
3. Check that no error messages about missing environment variables appear
4. Verify API calls are working correctly

## Files Modified

- `backend/app/bedrock.py` - Added secure configuration and client factory
- `backend/app/stream.py` - Updated to use secure client factory
- `SECURITY_CONFIGURATION.md` - This documentation file

## Next Steps

1. Set up your environment variables
2. Test the application with the new secure configuration
3. Consider implementing additional security measures for production deployment
4. Review and update your deployment scripts to include environment variable configuration 