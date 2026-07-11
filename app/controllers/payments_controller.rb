class PaymentsController < ApplicationController
  def show
    @payment = current_account.payments.find(params[:id])
  end
end
