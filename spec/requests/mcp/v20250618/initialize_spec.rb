require 'rails_helper'

RSpec.describe "MCP Initialization", type: :request do
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }
  let(:initialization_payload) do
    {
      "jsonrpc": "2.0",
      "id": 1,
      "method": "initialize",
      "params": {
        "protocolVersion": "2025-06-18",
        "capabilities": {
          "roots": {
            "listChanged": true
          },
          "sampling": {},
          "elicitation": {}
        },
        "clientInfo": {
          "name": "ExampleClient",
          "title": "Example Client Display Name",
          "version": "1.0.0"
        }
      }
    }.to_json
  end

  it "returns 200 ok" do
    post mcp_v20250618_url, params: initialization_payload, headers: headers
    expect(response).to be_successful
  end

  it "returns JSON" do
    post mcp_v20250618_url, params: initialization_payload, headers: headers
    expect { JSON.parse(response.body) }.not_to raise_error
  end

  it "returns protocol version 2025-06-18" do
    post mcp_v20250618_url, params: initialization_payload, headers: headers
    expect(JSON.parse(response.body).dig("result", "protocolVersion")).to eq "2025-06-18"
  end
end
