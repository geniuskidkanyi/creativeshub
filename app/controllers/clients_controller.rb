class ClientsController < ApplicationController
  before_action :set_client, only: [ :show, :edit, :update, :destroy ]

  def index
    @clients = current_account.clients.ordered
  end

  def show
  end

  def new
    @client = current_account.clients.new
  end

  def create
    @client = current_account.clients.new(client_params)

    if @client.save
      respond_to do |format|
        format.html { redirect_to clients_path, notice: "Client was successfully added." }
        format.json { render json: { id: @client.id, name: @client.name, email: @client.email, company: @client.company }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @client.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def search
    query = params[:q].to_s.strip
    clients = if query.present?
      current_account.clients.where("name ILIKE ? OR email ILIKE ? OR company ILIKE ?", "%#{query}%", "%#{query}%", "%#{query}%").limit(10)
    else
      current_account.clients.ordered.limit(10)
    end

    render json: clients.map { |c| { id: c.id, name: c.name, email: c.email, company: c.company } }
  end

  def edit
  end

  def update
    if @client.update(client_params)
      redirect_to clients_path, notice: "Client was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @client.destroy
    redirect_to clients_path, notice: "Client was successfully removed."
  end

  private

  def set_client
    @client = current_account.clients.find(params[:id])
  end

  def client_params
    params.require(:client).permit(:name, :email, :phone, :company, :address)
  end
end
