class RegistrationsController < Devise::RegistrationsController
  def create
    build_resource(sign_up_params)

    ActiveRecord::Base.transaction do
      account = Account.create!(business_name: params[:business_name])
      resource.account = account
      resource.role = :owner
      resource.save!

      if resource.persisted?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    clean_up_passwords resource
    set_minimum_password_length
    respond_with resource
  end
end
