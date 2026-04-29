require 'rails_helper'

RSpec.describe Agent do
  let(:mcp_request_base) { { jsonrpc: "2.0", id: "test-#{SecureRandom.base36}" } }

  let(:mcp_server) do
    Class.new { include Agent }.new.send(:mcp_server, {})
  end

  def send_to_server(request)
    JSON.parse(mcp_server.handle_json(request.to_json).as_json)
  end

  it "handles initialize request" do
    payload = send_to_server(mcp_request_base.merge(method: :initialize))
    expect(payload["result"]).to be_truthy
  end

  it "handles ping request" do
    payload = send_to_server(mcp_request_base.merge(method: :ping))
    expect(payload["result"]).to eq({})
  end

  it "handles resources/list" do
    payload = send_to_server(mcp_request_base.merge(method: "resources/list"))
    expect(payload["result"]).to have_key("resources")
  end

  it "handles resources/read for mpi://info" do
    payload = send_to_server(mcp_request_base.merge(method: "resources/read", params: { uri: "mpi://info" }))
    expect(payload["result"]).to have_key("contents")
  end
end
