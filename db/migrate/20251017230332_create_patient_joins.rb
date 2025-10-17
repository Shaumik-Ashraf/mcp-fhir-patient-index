class CreatePatientJoins < ActiveRecord::Migration[8.0]
  def change
    create_table :patient_joins do |t|
      t.references :from_patient_record, null: false, foreign_key: true
      t.references :to_patient_record, null: false, foreign_key: true
      t.integer :qualifier
      t.text :notes

      t.timestamps
    end
  end
end
