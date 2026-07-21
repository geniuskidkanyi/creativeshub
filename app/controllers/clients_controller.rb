class ClientsController < ApplicationController
  before_action :set_client, only: [ :show, :edit, :update, :destroy ]

  def index
    @q = params[:q].to_s.strip
    scope = current_account.clients
    scope = @q.present? ? scope.search_all(@q) : scope.ordered
    @pagy, @clients = pagy(scope, limit: 20)
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
      current_account.clients.search_all(query).limit(10)
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
