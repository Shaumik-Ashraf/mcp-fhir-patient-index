require 'rails_helper'

RSpec.describe "MCP Initialization", type: :request do
  let(:headers) { { "CONTENT_TYPE" => "application/json", "MCP-Protocol-Version" => "2025-06-18" } }
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

  it "returns 405 for GET requests" do
    get mcp_v20250618_url
    expect(response).to have_http_status(:method_not_allowed)
  end

  it "returns 400 for unsupported MCP-Protocol-Version" do
    post mcp_v20250618_url,
         params: initialization_payload,
         headers: headers.merge("MCP-Protocol-Version" => "2024-11-05")
    expect(response).to have_http_status(:bad_request)
  end

  it "accepts requests without MCP-Protocol-Version header" do
    headers_without_version = headers.merge("MCP-Protocol-Version" => nil)
    post mcp_v20250618_url, params: initialization_payload, headers: headers
    expect(response).to be_successful
  end
end
