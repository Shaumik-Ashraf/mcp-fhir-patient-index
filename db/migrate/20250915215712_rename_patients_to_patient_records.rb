class RenamePatientsToPatientRecords < ActiveRecord::Migration[8.0]
  def change
    if ActiveRecord::Base.connection.table_exists? "patients"
      rename_table("patients", "patient_records")
    elsif ActiveRecord::Base.connection.table_exists? "patient_records"
      # do nothing
    else
      create_table :patient_records do |t|
        t.string :uuid, null: false
        t.string :first_name
        t.string :last_name
        t.integer :administrative_gender
        t.date :birth_date
        t.string :email
        t.string :phone_number
        t.string :address_line1
        t.string :address_line2
        t.string :address_city
        t.string :address_state
        t.string :address_zip_code
        t.string :social_security_number
        t.string :passport_number
        t.string :drivers_license_number

        t.timestamps
      end
      add_index :patient_records, :uuid, unique: true
    end
  end
end
