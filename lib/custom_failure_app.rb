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

      # When the failure happens inside a mounted engine (Avo at
      # /platformadmin), redirect_to would prepend the engine's SCRIPT_NAME and
      # send the user to /platformadmin/users/sign_in — still inside the
      # admin-only mount, so it fails auth and redirects again, looping. Clear
      # SCRIPT_NAME so the login path resolves against the app root.
      request.script_name = ""
      redirect_to new_user_session_path
    end
  end

  private

  def navigational_format?
    request.format.html? || request.format.turbo_stream?
  end
end
