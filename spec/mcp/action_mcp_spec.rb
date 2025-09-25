require 'rails_helper'

RSpec.describe ActionMCP do
  let(:mcp_request) { ActionDispatch::Request.new({}) }
  let(:ping_body) { { jsonrpc: "2.0", id: "test", method: "ping" }.to_json }

  before do
    allow(mcp_request).to receive(:body).and_return(StringIO.new(ping_body))
  end

  describe '#handle_json' do
    it 'returns jsonable object' do
      expect(described_class.handle_json(mcp_request)).to respond_to :as_json
    end
  end
end
