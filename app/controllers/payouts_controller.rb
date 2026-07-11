class PayoutsController < ApplicationController
  before_action :require_settlement_details!, only: [ :new, :create ]

  def index
    @payouts = current_account.payouts.ordered
  end

  def new
    @available_balance = current_account.available_payout_balance
    @payout = current_account.payouts.new(
      currency: current_account.currency.presence || "GMD",
      network: current_account.settlement_code,
      account_number: current_account.settlement_account_number,
      beneficiary_name: current_account.business_name
    )
  end

  def create
    @available_balance = current_account.available_payout_balance
    @payout = current_account.payouts.new(payout_params.merge(idempotency_key: SecureRandom.uuid, status: :pending))

    unless @payout.valid?
      flash.now[:alert] = @payout.errors.full_messages.to_sentence
      return render :new, status: :unprocessable_entity
    end

    fee_result = ModemPayService.transfer_fee(amount: @payout.amount, currency: @payout.currency, network: @payout.network)
    unless fee_result.success?
      flash.now[:alert] = "Could not confirm the transfer fee: #{fee_result.error}"
      return render :new, status: :unprocessable_entity
    end

    @payout.fee = fee_result.raw_response["fee"]

    if @payout.total_debit > @available_balance
      flash.now[:alert] = "Amount plus the D#{@payout.fee} transfer fee exceeds your available balance."
      return render :new, status: :unprocessable_entity
    end

    @payout.save!

    result = ModemPayService.create_transfer(
      amount: @payout.amount,
      currency: @payout.currency,
      network: @payout.network,
      account_number: @payout.account_number,
      beneficiary_name: @payout.beneficiary_name,
      narration: @payout.narration.presence || "SmartPay payout — #{current_account.business_name}",
      metadata: { payout_id: @payout.id, account_id: current_account.id },
      idempotency_key: @payout.idempotency_key
    )

    if result.success?
      @payout.update!(
        modempay_transfer_id: result.transfer_id,
        transfer_reference: result.transfer_reference,
        fee: result.transfer_fee.presence || @payout.fee,
        status: result.transfer_status == "completed" ? :completed : :pending
      )
      redirect_to payouts_path, notice: "Payout of D#{@payout.amount.to_i} sent to #{@payout.network.titleize} wallet #{@payout.account_number}."
    else
      @payout.update!(status: :failed, error_message: result.error)
      redirect_to payouts_path, alert: "Payout failed: #{result.error}"
    end
  end

  private

  def payout_params
    params.require(:payout).permit(:amount, :network, :account_number, :beneficiary_name, :narration)
          .with_defaults(currency: current_account.currency.presence || "GMD")
  end

  def require_settlement_details!
    unless current_account.modempay_sub_account_ready?
      redirect_to edit_account_path, alert: "Add your settlement provider and wallet number in Business Settings before requesting a payout."
    end
  end
end
