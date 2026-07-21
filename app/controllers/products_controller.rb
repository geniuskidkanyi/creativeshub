class ProductsController < ApplicationController
  before_action :set_product, only: [ :show, :edit, :update, :destroy ]

  def index
    @q = params[:q].to_s.strip
    scope = current_account.products
    scope = @q.present? ? scope.search_all(@q) : scope.ordered
    @pagy, @products = pagy(scope, limit: 20)
  end

  def show
  end

  def new
    @product = current_account.products.new
  end

  def create
    @product = current_account.products.new(product_params)

    respond_to do |format|
      if @product.save
        format.html { redirect_to products_path, notice: "Product was successfully added." }
        format.json { render json: product_json(@product), status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity }
      end
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
      current_account.products.search_all(query).limit(10)
    else
      current_account.products.ordered.limit(10)
    end

    render json: products.map { |p| product_json(p) }
  end

  private

  def product_json(product)
    { id: product.id, name: product.name, description: product.description, unit_price: product.unit_price.to_f }
  end

  def set_product
    @product = current_account.products.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :description, :unit_price)
  end
end
