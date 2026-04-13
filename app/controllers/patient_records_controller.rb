class PatientRecordsController < ApplicationController
  include Auditable

  before_action :set_patient_record, only: %i[ show edit update destroy unlink ]

  after_action :audit_patient_index, only: [ :index ]
  after_action :audit_patient_show, only: [ :show ]
  after_action :audit_patient_create, only: [ :create ]
  after_action :audit_patient_update, only: [ :update ]
  after_action :audit_patient_destroy, only: [ :destroy ]
  after_action :audit_auto_match, only: [ :auto_match ]
  after_action :audit_unlink, only: [ :unlink ]

  after_action :audit_patient_index, only: [ :index ]
  after_action :audit_patient_show, only: [ :show ]
  after_action :audit_patient_create, only: [ :create ]
  after_action :audit_patient_update, only: [ :update ]
  after_action :audit_patient_destroy, only: [ :destroy ]
  after_action :audit_auto_match, only: [ :auto_match ]
  after_action :audit_unlink, only: [ :unlink ]

  # GET /patients
  def index
    set_title "Patients"
    @patient_records = PatientRecord.all

    respond_to do |format|
      format.html
      format.json do
        scope = @patient_records

        if params[:search].present?
          term = "%#{params[:search]}%"
          scope = scope.where("first_name LIKE ? OR last_name LIKE ?", term, term)
        end

        allowed_columns = %w[first_name last_name birth_date]
        sort_col = allowed_columns.include?(params[:sort_column]) ? params[:sort_column] : "last_name"
        sort_dir = params[:sort_direction] == "desc" ? "desc" : "asc"
        scope = scope.order("#{sort_col} #{sort_dir}")

        total = scope.count
        page = [ params[:page].to_i, 1 ].max
        per_page = (params[:per_page] || 25).to_i.clamp(1, 100)
        records = scope.offset((page - 1) * per_page).limit(per_page)

        group_map = PatientGroup.index_by_patient_record_id

        render json: {
          data: records.map { |r|
            { first_name: r.first_name, last_name: r.last_name, birth_date: r.birth_date, linked_records_count: r.linked_records.count, group_index: group_map[r.id], uuid: r.uuid }
          },
          total: total
        }
      end
    end
  end

  # POST /patient_records/auto_match
  def auto_match
    threshold = Setting[:auto_match_threshold].to_f
    engine    = MatchingEngine.new
    records   = PatientRecord.all.to_a
    group_map = PatientGroup.index_by_patient_record_id

    # Give unlinked records a unique sentinel group so already_linked? works uniformly.
    # Negative IDs avoid collision with real (positive) group indices.
    records.each { |r| group_map[r.id] ||= -r.id }

    joins_created = 0
    records.combination(2) do |r1, r2|
      next if PatientGroup.already_linked?(r1.id, r2.id, group_map: group_map)
      next unless engine.match?(PatientMatchInput.from_patient_record(r1), PatientMatchInput.from_patient_record(r2), threshold: threshold)

      PatientJoin.create!(
        from_patient_record: r1,
        to_patient_record: r2,
        qualifier: :has_same_identity_as
      )
      joins_created += 1

      # Merge the two components in-memory so later pairs in the same run
      # don't produce redundant links into the same growing component.
      old_group = group_map[r2.id]
      new_group = group_map[r1.id]
      group_map.transform_values! { |g| g == old_group ? new_group : g }
    end

    redirect_to patient_records_path,
      notice: "Auto-match complete: #{joins_created} new link(s) created."
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

    def audit_interface
      AuditLog::Interface::WEB
    end

    def set_patient_record
      @patient_record = PatientRecord.find_by_uuid(params.expect(:id))
    end

    def patient_record_params
      params.expect(patient_record: [ :first_name, :last_name, :administrative_gender, :birth_date, :email, :phone_number, :social_security_number, :address_line1, :address_line2, :address_city, :address_state, :address_zip_code, :social_security_number, :passport_number, :drivers_license_number ])
    end
end
