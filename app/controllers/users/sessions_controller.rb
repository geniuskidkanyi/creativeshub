class Users::SessionsController < Devise::SessionsController
  def create
    self.resource = resource_class.find_for_database_authentication(email: sign_in_params[:email])

    if resource && resource.valid_password?(sign_in_params[:password])
      if resource.active_for_authentication?
        set_flash_message!(:notice, :signed_in)
        sign_in(resource_name, resource)
        yield resource if block_given?
        respond_with resource, location: after_sign_in_path_for(resource)
      else
        set_flash_message!(:alert, :unconfirmed)
        redirect_to new_user_session_path, status: :see_other
      end
    else
      flash[:alert] = "Invalid Email or password."
      redirect_to new_user_session_path, status: :see_other
    end
  end
end
