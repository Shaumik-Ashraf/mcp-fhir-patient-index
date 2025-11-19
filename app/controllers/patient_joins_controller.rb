class PatientJoinsController < ApplicationController
  before_action :set_patient_records, only: [ :compare ]
  before_action :set_patient_join, only: [ :destroy ]

  # GET /patient_joins/new
  def new
    @patient_records = PatientRecord.all
  end

  # GET /patient_joins/compare
  def compare
    if @patient_record_1.nil? || @patient_record_2.nil?
      redirect_to new_patient_join_path, alert: "Please select two valid patient records to compare."
      return
    end

    if @patient_record_1.id == @patient_record_2.id
      redirect_to new_patient_join_path, alert: "Cannot link a patient record to itself."
      return
    end

    @patient_join = PatientJoin.new(
      from_patient_record: @patient_record_1,
      to_patient_record: @patient_record_2,
      qualifier: :has_same_identity_as
    )
  end

  # POST /patient_joins
  def create
    @patient_join = PatientJoin.new(patient_join_params)

    # Validate that the two patient records are different
    if @patient_join.from_patient_record_id == @patient_join.to_patient_record_id
      redirect_to new_patient_join_path, alert: "Cannot link a patient record to itself."
      return
    end

    # Check for existing join
    existing_join = PatientJoin.find_by(
      from_patient_record_id: @patient_join.from_patient_record_id,
      to_patient_record_id: @patient_join.to_patient_record_id
    )

    if existing_join
      redirect_to patient_record_path(@patient_join.from_patient_record), notice: "These patient records are already linked."
      return
    end

    if @patient_join.save
      redirect_to patient_record_path(@patient_join.from_patient_record),
                  notice: "Patient records successfully linked."
    else
      @patient_record_1 = @patient_join.from_patient_record
      @patient_record_2 = @patient_join.to_patient_record
      render :compare, status: :unprocessable_entity
    end
  end

  # DELETE /patient_joins/1
  def destroy
    from_patient = @patient_join.from_patient_record
    @patient_join.destroy!

    redirect_to patient_record_path(from_patient),
                notice: "Patient link removed.",
                status: :see_other
  end

  private

  def set_patient_records
    @patient_record_1 = PatientRecord.find_by_uuid(params[:patient_1_uuid]) if params[:patient_1_uuid].present?
    @patient_record_2 = PatientRecord.find_by_uuid(params[:patient_2_uuid]) if params[:patient_2_uuid].present?
  end

  def set_patient_join
    @patient_join = PatientJoin.find(params.expect(:id))
  end

  def patient_join_params
    params.expect(patient_join: [ :from_patient_record_id, :to_patient_record_id, :qualifier, :notes ])
  end
end
