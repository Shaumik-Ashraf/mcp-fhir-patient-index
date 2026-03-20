class PatientMatchInput
  attr_reader :social_security_number, :birth_date, :first_name, :last_name

  def initialize(social_security_number:, birth_date:, first_name:, last_name:)
    @social_security_number = social_security_number
    @birth_date = birth_date
    @first_name = first_name
    @last_name = last_name
  end

  # Build from a PatientRecord.
  #
  # @param [PatientRecord] record
  # @return [PatientMatchInput]
  def self.from_patient_record(record)
    new(
      social_security_number: record.social_security_number,
      birth_date: record.birth_date,
      first_name: record.first_name,
      last_name: record.last_name
    )
  end

  # Build from a FHIR::Patient resource (e.g. extracted from a $match Parameters body).
  # Symmetric counterpart to PatientRecord#to_fhir.
  #
  # @param [FHIR::Patient] fhir_patient
  # @return [PatientMatchInput]
  def self.from_fhir(fhir_patient)
    ssn = fhir_patient.identifier.find { |id|
      id.type&.coding&.any? { |c| c.code == "SS" }
    }&.value

    new(
      social_security_number: ssn,
      birth_date: fhir_patient.birthDate.presence && Date.parse(fhir_patient.birthDate),
      first_name: fhir_patient.name.first&.given&.first,
      last_name: fhir_patient.name.first&.family
    )
  end
end
