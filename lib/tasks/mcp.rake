namespace :mcp do
  task :load => [:environment] do
    include ActionMCP
  end

  desc "Run MCP Server in STDIO mode"
  task stdio: :load do
    mcp_stdio.open
  end
end
