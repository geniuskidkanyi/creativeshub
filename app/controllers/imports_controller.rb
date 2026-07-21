class ImportsController < ApplicationController
  before_action :set_import, only: [ :show, :commit, :destroy ]

  def index
    @imports = current_account.wave_imports.ordered.limit(20)
    @import = current_account.wave_imports.new
  end

  def show
  end

  def create
    @import = current_account.wave_imports.new(user: current_user, original_filename: import_params[:file]&.original_filename)
    @import.file.attach(import_params[:file]) if import_params[:file]

    if @import.save
      ProcessWaveImportJob.perform_later(@import, mode: :preview)
      redirect_to import_path(@import), notice: "Reading your file…"
    else
      @imports = current_account.wave_imports.ordered.limit(20)
      render :index, status: :unprocessable_entity
    end
  end

  def commit
    unless @import.previewed? && @import.supported?
      return redirect_to import_path(@import), alert: "This import isn't ready to run."
    end

    ProcessWaveImportJob.perform_later(@import, mode: :commit)
    redirect_to import_path(@import), notice: "Importing — this page updates as it runs."
  end

  def destroy
    @import.destroy
    redirect_to imports_path, notice: "Import removed."
  end

  private

  def set_import
    @import = current_account.wave_imports.find(params[:id])
  end

  def import_params
    params.require(:wave_import).permit(:file)
  end
end
