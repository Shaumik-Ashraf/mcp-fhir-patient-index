FactoryBot.define do
  factory :audit_log do
    description { "Test audit log entry" }
    tags { { AuditLog::Tag::EVENT => AuditLog::Event::PATIENT_READ, AuditLog::Tag::INTERFACE => AuditLog::Interface::WEB } }
    encrypted_request { { params: {} } }
    encrypted_response { { status: 200 } }
  end
end
