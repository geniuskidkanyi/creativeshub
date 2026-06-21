class ProductsController < ApplicationController
  before_action :set_product, only: [ :show, :edit, :update, :destroy ]

  def index
    @products = current_account.products.ordered
  end

  def show
  end

  def new
    @product = current_account.products.new
  end

  def create
    @product = current_account.products.new(product_params)

    if @product.save
      redirect_to products_path, notice: "Product was successfully added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to products_path, notice: "Product was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to products_path, notice: "Product was successfully removed."
  end

  def search
    query = params[:q].to_s.strip
    products = if query.present?
      current_account.products.where("name ILIKE ?", "%#{query}%").limit(10)
    else
      current_account.products.ordered.limit(10)
    end

    render json: products.map { |p| { id: p.id, name: p.name, description: p.description, unit_price: p.unit_price.to_f } }
  end

  private

  def set_product
    @product = current_account.products.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :description, :unit_price)
  end
end
