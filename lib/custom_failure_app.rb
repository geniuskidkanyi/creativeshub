class CustomFailureApp < Devise::FailureApp
  def respond
    if http_auth? && !navigational_format?
      http_auth
    else
      store_location!
      # Lets the sign-in page offer a one-click confirmation resend.
      if warden_message == :unconfirmed
        flash[:unconfirmed_email] = request.params.dig("user", "email").presence
      end
      flash[:alert] = i18n_message
      redirect_to new_user_session_path
    end
  end

  private

  def navigational_format?
    request.format.html? || request.format.turbo_stream?
  end
end
