# LOCAL-LLM-Stack User Cheat Sheet

## Quick Start

```bash
# Start the stack
./llm start

# Start with additional modules
./llm start --with monitoring
./llm start --with security
./llm start --with scaling

# Stop the stack
./llm stop

# Check status
./llm status
```

## Model Management

```bash
# List available models
./llm models list

# Add a model
./llm models add llama3

# Remove a model
./llm models remove llama3
```

## Configuration

```bash
# Generate secure secrets
./llm generate-secrets

# View configuration
./llm config show

# Edit configuration
./llm config edit
```

## Debugging

```bash
# Start in debug mode
./llm debug

# Debug specific component
./llm debug librechat
```

## Help

```bash
# Show all commands
./llm help

# Get help for specific command
./llm help start
./llm help models
```

## Access Points

- LibreChat Web Interface: http://localhost:3080
- Ollama API: http://localhost:11434
- Grafana (if monitoring enabled): http://localhost:3000
- Prometheus (if monitoring enabled): http://localhost:9090

## Common Issues

### No LLMs displayed in LibreChat
Check if Ollama is running and properly configured in LibreChat.

```bash
# Restart Ollama
./llm stop
./llm start ollama

# Check Ollama status
curl -s http://localhost:11434/api/tags
```

### Authentication Issues
Default admin credentials are generated during setup. Find them in the output of:

```bash
./llm generate-secrets
```

### Resource Limitations
Adjust resource limits in `config/.env` if you experience performance issues:

```bash
# Edit configuration
./llm config edit
```

Key settings to adjust:
- `OLLAMA_MEMORY_LIMIT`
- `OLLAMA_CPU_LIMIT`