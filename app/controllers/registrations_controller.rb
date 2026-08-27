class RegistrationsController < Devise::RegistrationsController
  def create
    build_resource(sign_up_params)

    ActiveRecord::Base.transaction do
      account = Account.create!(business_name: params[:business_name])
      resource.account = account
      resource.role = :owner
      resource.save!

      if resource.persisted?
        track_ga_event("sign_up", method: "email")

        if resource.active_for_authentication?
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          expire_data_after_sign_in!
          redirect_to new_user_session_path, notice: "Account created! Please check your email to confirm your account."
        end
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
