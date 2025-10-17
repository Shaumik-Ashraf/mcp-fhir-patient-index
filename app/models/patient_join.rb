class PatientJoin < ApplicationRecord
  belongs_to :from_patient_record, class_name: "PatientRecord"
  belongs_to :to_patient_record, class_name: "PatientRecord"

  # I have a structured data field to capture the nature of the
  # directional self-join relationship. Although there is only
  # one such relationship at the moment more could easily be added.
  enum :qualifier, %i[ has_same_identity_as ]
end
