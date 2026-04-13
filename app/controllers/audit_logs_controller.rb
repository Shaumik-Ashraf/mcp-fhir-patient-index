class AuditLogsController < ApplicationController
  before_action :set_audit_log, only: [ :show, :download_request, :download_response ]

  # GET /audit_logs
  def index
    set_title "Audit Log"
    @audit_logs = AuditLog.order(created_at: :desc)

    if params[:interface].present?
      @audit_logs = @audit_logs.where("JSON_EXTRACT(tags, '$.interface') = ?", params[:interface])
    end

    if params[:event].present?
      @audit_logs = @audit_logs.where("JSON_EXTRACT(tags, '$.event') = ?", params[:event])
    end
  end

  # GET /audit_logs/:id
  def show
    set_title "Audit Log ##{@audit_log.id}"
  end

  # GET /audit_logs/:id/download_request
  def download_request
    send_data @audit_log.encrypted_request.to_json,
              filename: "audit_log_#{@audit_log.id}_request.json",
              type: "application/json"
  end

  # GET /audit_logs/:id/download_response
  def download_response
    send_data @audit_log.encrypted_response.to_json,
              filename: "audit_log_#{@audit_log.id}_response.json",
              type: "application/json"
  end

  private

  def set_audit_log
    @audit_log = AuditLog.find(params[:id])
  end
end
