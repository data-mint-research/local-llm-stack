# Known Issues and Limitations

This document lists known issues and limitations in the LOCAL-LLM-Stack system. It provides information about each issue, its impact, and potential workarounds.

## Table of Contents

1. [System Limitations](#system-limitations)
2. [Configuration Issues](#configuration-issues)
3. [Docker-Related Issues](#docker-related-issues)
4. [Component-Specific Issues](#component-specific-issues)
5. [Module-Specific Issues](#module-specific-issues)
6. [Performance Issues](#performance-issues)
7. [Reporting New Issues](#reporting-new-issues)

## System Limitations

### Resource Requirements

**Issue**: The system requires significant resources, especially when running multiple LLM models.

**Impact**: On systems with limited resources, performance may degrade or components may fail to start.

**Workaround**: 
- Adjust resource limits in configuration files
- Run fewer components simultaneously
- Use smaller LLM models
- Increase system resources (RAM, CPU)

### Concurrent User Limit

**Issue**: The system has been tested with up to 10 concurrent users.

**Impact**: Performance may degrade with more than 10 concurrent users.

**Workaround**:
- Implement a queue system for user requests
- Scale horizontally by deploying multiple instances
- Upgrade hardware resources

### Network Dependencies

**Issue**: The system relies on Docker's internal networking.

**Impact**: In complex network environments, container communication may be affected.

**Workaround**:
- Ensure Docker network settings are properly configured
- Use explicit IP addresses instead of container names if necessary
- Check firewall rules that might affect container communication

## Configuration Issues

### Environment Variable Precedence

**Issue**: Environment variables defined in multiple places may cause unexpected behavior.

**Impact**: Configuration values may not be what you expect if defined in multiple locations.

**Workaround**:
- Use a single source of truth for configuration values
- Check all possible configuration locations when troubleshooting
- Use the `llm config show` command to see the effective configuration

### Secret Management Limitations

**Issue**: Secrets are stored in environment files with limited encryption.

**Impact**: Secrets may be exposed if the configuration files are compromised.

**Workaround**:
- Ensure proper file permissions on configuration files
- Use external secret management solutions for production environments
- Regularly rotate secrets

### Configuration Validation Limitations

**Issue**: Configuration validation may not catch all possible errors.

**Impact**: Some invalid configurations may pass validation but cause runtime errors.

**Workaround**:
- Test configuration changes in a non-production environment
- Monitor logs for configuration-related errors
- Follow the configuration templates closely

## Docker-Related Issues

### Docker Version Compatibility

**Issue**: The system has been tested with Docker 20.10.x and Docker Compose V2.

**Impact**: Older or newer versions of Docker may have compatibility issues.

**Workaround**:
- Use the recommended Docker version
- Test thoroughly if using a different version
- Check Docker compatibility before upgrading

### Docker Resource Allocation

**Issue**: Docker may not properly release resources after container stops.

**Impact**: System may become resource-constrained after multiple start/stop cycles.

**Workaround**:
- Restart Docker daemon periodically
- Monitor Docker resource usage
- Use `docker system prune` to clean up unused resources

### Docker Network Conflicts

**Issue**: Docker network name conflicts may occur if you have other Docker projects.

**Impact**: Container networking may fail if network names conflict.

**Workaround**:
- Use unique network names
- Check for existing networks before creating new ones
- Remove unused networks

## Component-Specific Issues

### Ollama

#### Model Loading Time

**Issue**: Initial model loading can take significant time.

**Impact**: First requests after starting Ollama may time out or be very slow.

**Workaround**:
- Pre-load models during system startup
- Increase request timeouts for initial requests
- Implement retry logic for failed requests

#### Model Size Limitations

**Issue**: Large models may exceed available system memory.

**Impact**: Ollama may crash or fail to load large models on systems with limited memory.

**Workaround**:
- Use smaller models
- Increase system memory
- Adjust Ollama memory limits in configuration

### LibreChat

#### Authentication Issues

**Issue**: LibreChat authentication may fail after configuration changes.

**Impact**: Users may be unable to log in after changing authentication settings.

**Workaround**:
- Clear browser cookies and cache
- Restart LibreChat container
- Check authentication configuration

#### API Rate Limiting

**Issue**: LibreChat may experience rate limiting when making many requests to Ollama.

**Impact**: Users may see errors or timeouts during heavy usage.

**Workaround**:
- Implement request queuing
- Increase rate limits if possible
- Distribute load across multiple instances

### MongoDB

#### Data Directory Permissions

**Issue**: MongoDB may fail to start due to data directory permission issues.

**Impact**: The system may fail to start or lose data.

**Workaround**:
- Ensure proper permissions on the MongoDB data directory
- Run the container with appropriate user permissions
- Check MongoDB logs for permission-related errors

#### Memory Usage Growth

**Issue**: MongoDB memory usage may grow over time.

**Impact**: System performance may degrade as MongoDB consumes more memory.

**Workaround**:
- Configure MongoDB memory limits
- Implement regular database maintenance
- Monitor MongoDB memory usage

### Meilisearch

#### Index Rebuilding

**Issue**: Meilisearch may need to rebuild indexes after configuration changes.

**Impact**: Search functionality may be temporarily unavailable or slow.

**Workaround**:
- Schedule index rebuilding during low-usage periods
- Monitor Meilisearch logs for indexing status
- Implement fallback search mechanisms

## Module-Specific Issues

### Monitoring Module

#### Grafana Dashboard Loading

**Issue**: Grafana dashboards may not load automatically.

**Impact**: Monitoring dashboards may need manual setup.

**Workaround**:
- Import dashboards manually
- Check Grafana logs for errors
- Ensure Prometheus is properly configured

#### Prometheus Data Retention

**Issue**: Prometheus data retention is limited by default.

**Impact**: Historical monitoring data may be lost after the retention period.

**Workaround**:
- Configure longer data retention periods
- Export important metrics to external storage
- Use Grafana snapshots for important dashboards

### Security Module

#### Traefik Certificate Renewal

**Issue**: Traefik may fail to renew Let's Encrypt certificates automatically.

**Impact**: HTTPS connections may fail when certificates expire.

**Workaround**:
- Monitor certificate expiration dates
- Implement certificate renewal monitoring
- Have a process for manual certificate renewal

## Performance Issues

### High CPU Usage

**Issue**: The system may use high CPU during inference operations.

**Impact**: Other system processes may be affected during heavy usage.

**Workaround**:
- Limit CPU usage in Docker configuration
- Use CPU-optimized models
- Schedule resource-intensive operations during off-peak hours

### Memory Leaks

**Issue**: Some components may have memory leaks during extended operation.

**Impact**: System performance may degrade over time.

**Workaround**:
- Restart components periodically
- Monitor memory usage
- Implement memory usage alerts

### Disk I/O Bottlenecks

**Issue**: Heavy disk I/O may cause performance bottlenecks.

**Impact**: System responsiveness may decrease during heavy disk operations.

**Workaround**:
- Use SSD storage for data directories
- Optimize disk I/O patterns
- Monitor disk usage and performance

## Reporting New Issues

If you encounter an issue not listed here, please report it with the following information:

1. **Issue Description**: A clear and concise description of the issue
2. **System Information**: Docker version, host OS, hardware specifications
3. **Steps to Reproduce**: Detailed steps to reproduce the issue
4. **Expected Behavior**: What you expected to happen
5. **Actual Behavior**: What actually happened
6. **Logs and Error Messages**: Relevant logs and error messages
7. **Screenshots**: If applicable, add screenshots to help explain the issue
8. **Additional Context**: Any other context about the issue

This information will help diagnose and resolve the issue more quickly.