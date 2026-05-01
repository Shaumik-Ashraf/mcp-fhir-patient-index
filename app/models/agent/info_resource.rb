module Agent
  class InfoResource < ApplicationResource
    def self.resource
      MCP::Resource.new(
        uri: "#{Agent::SCHEME}://info",
        name: "info",
        title: "MCP Server Info",
        description: "Information about this Master Patient Index MCP server",
        mime_type: "text/plain"
      )
    end

    def self.read
      <<~EOT
        This is a master patient index server that supports model context
        protocol (MCP). It contains patient records of demographic information
        for retrieval, matching, and de-duplication.
      EOT
    end
  end
end
