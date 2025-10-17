class CreatePatientJoins < ActiveRecord::Migration[8.0]
  def change
    create_table :patient_joins do |t|
      t.references :from_patient_record, null: false, foreign_key: { to_table: :patient_records }
      t.references :to_patient_record, null: false, foreign_key: { to_table: :patient_records }
      t.integer :qualifier
      t.text :notes

      t.timestamps
    end
  end
end
