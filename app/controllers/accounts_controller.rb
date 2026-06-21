class AccountsController < ApplicationController
  skip_before_action :require_account!, only: [ :new, :create ]

  def new
    @account = Account.new
  end

  def create
    @account = Account.new(account_params)

    if @account.save
      current_user.update!(account: @account, role: :owner)
      redirect_to dashboard_path, notice: "Account created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @account = current_account
  end

  def update
    @account = current_account

    if params[:remove_logo] == "1"
      @account.logo.purge
    end

    if @account.update(account_params)
      redirect_to edit_account_path, notice: "Settings saved successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.require(:account).permit(:business_name, :address, :phone, :website, :tax_id, :currency, :timezone, :logo, :settlement_code, :settlement_account_number)
  end
end
