class PatientRecordsController < ApplicationController
  before_action :set_patient_record, only: %i[ show edit update destroy unlink ]

  # GET /patients
  def index
    set_title "Patients"
    @patient_records = PatientRecord.all
  end

  # GET /patients/1
  def show
    set_title "Patient #{@patient_record.uuid}"
  end

  # GET /patients/new
  def new
    set_title "Add Patient"
    @patient_record = PatientRecord.new
  end

  # GET /patients/1/edit
  def edit
    set_title "Edit Patient #{@patient_record.uuid}"
  end

  # POST /patients
  def create
    @patient_record = PatientRecord.new(patient_record_params)

    if @patient_record.save
      redirect_to @patient_record, notice: "Patient Record #{@patient_record.uuid} created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /patients/1
  def update
    snapshot = @patient_record.create_snapshot!(
      identifier: "patient_record_snapshot_#{@patient_record.uuid}",
      metadata: {
        controller: params[:controller],
        action: params[:action]
      }
    )

    if @patient_record.update(patient_record_params)
      redirect_to @patient_record, notice: "Patient Record #{@patient_record.saved_changes.keys.join(',')} updated.", status: :see_other
    else
      # undo snapshot since save was unsuccessful
      snapshot.destroy!
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /patients/1/unlink
  def unlink
    PatientJoin.where(from_patient_record: @patient_record)
               .or(PatientJoin.where(to_patient_record: @patient_record))
               .destroy_all
    redirect_back fallback_location: patient_records_path,
                  notice: "Patient record removed from network.",
                  status: :see_other
  end

  # DELETE /patients/1
  def destroy
    @patient_record.create_snapshot!(
      identifier: "patient_record_snapshot_#{@patient_record.uuid}",
      metadata: {
        controller: params[:controller],
        action: params[:action]
      }
    )

    @patient_record.destroy!
    redirect_to patients_path, notice: "Patient Record #{@patient_record.uuid} permanently destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_patient_record
      @patient_record = PatientRecord.find_by_uuid(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def patient_record_params
      params.expect(patient_record: [ :first_name, :last_name, :administrative_gender, :birth_date, :email, :phone_number, :social_security_number, :address_line1, :address_line2, :address_city, :address_state, :address_zip_code, :social_security_number, :passport_number, :drivers_license_number ])
    end
end
