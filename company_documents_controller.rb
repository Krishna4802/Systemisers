class Api::V1::CompanyDocumentsController < ApplicationController
  include ProjectReportConcern
  before_action :authenticate_user!
  before_action :set_company_details,  except: :index

  def index
    company_documents = CompanyDocument.where(company_id: User.company_id)
    render json: { data: CompanyDocumentSerializer.render_as_json(company_documents) }, status: :ok
  end

  def show
    render json: { data: CompanyDocumentSerializer.render_as_json(@company_document) }, status: :ok
  end

  def create
    result = CompanyDocument.store_document(company_doc_permit, params[:file])
      data_present = result ? "File uploaded successfully"  : "file dont have all required paths"
      render json: { data: data_present  }, status: :created
  end

  def destroy
    return render json: { error: "Unable to delete company document" }, status: :unprocessable_entity unless  @company_document.destroy
    render json: { message: "company document deleted successfully" }, status: :ok
  end

  private
  def set_company_details
    @company_document = CompanyDocument.find_by(id: params[:id])
  end
end
