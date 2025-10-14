require 'rails_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe ApplicationMCP do
  let(:mcp_request_base) { { jsonrpc: "2.0", id: "test-#{SecureRandom.base36}" } }
  let(:ping_request) { mcp_request_base.merge({ method: :ping }) }
  let(:initialize_request) { mcp_request_base.merge({ method: :initialize }) }
  let(:list_resource_request) { mcp_request_base.merge({ method: "resources/list" }) }
  let(:read_resource_request) { mcp_request_base.merge({ method: "resources/read", params: { uri: "master-patient-index://info" } }) }
  #let(:list_resource_template_request) { mcp_request_base.merge({ method: "resources/templates/list" }) }

  let :mcp_server do
    Class.new do
      include ApplicationMCP
    end.new.server
  end

  def send_to_server(mcp_request)
    mcp_response = mcp_server.handle_json(mcp_request.to_json)
    JSON.parse(mcp_response.as_json)
  end

  describe '#server' do
    it "handles initialize request" do
      payload = send_to_server(initialize_request)
      expect(payload["result"]).to be_truthy
    end

    it "handles ping request" do
      payload = send_to_server(initialize_request)
      expect(payload["result"]).to be_truthy
    end

    it "handles resources list request" do
      payload = send_to_server(list_resource_request)
      expect(payload["result"]).to have_key "resources"
    end

    it "handles read resource info" do
      payload = send_to_server(read_resource_request)
      expect(payload["result"]).to have_key "contents"
    end

    # TODO: more thorough tests
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
