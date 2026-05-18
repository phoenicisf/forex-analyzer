# MCP Server Setup Guide

**Windows (PowerShell):**

```powershell
claude mcp add notebooklm -- cmd /c npx notebooklm-mcp@latest
claude mcp add docker -- uvx docker-mcp
claude mcp add markitdown -- uvx markitdown-mcp
claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server
claude mcp add playwright -- cmd /c npx -y @playwright/mcp --browser chrome
claude mcp add pare-git -e PARE_GIT_TOOLS=status,log,diff,show -- cmd /c npx -y @paretools/git
```

---
