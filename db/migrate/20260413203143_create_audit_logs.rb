class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.text :description
      t.json :tags
      t.json :encrypted_request
      t.json :encrypted_response

      t.timestamps
    end
  end
end
