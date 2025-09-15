class RenamePatientsToPatientRecords < ActiveRecord::Migration[8.0]
  def change
    rename_table("patients", "patient_records")
  end
end
