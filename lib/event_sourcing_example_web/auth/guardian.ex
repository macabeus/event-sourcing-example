defmodule EventSourcingExampleWeb.Auth.Guardian do
  use Amnesia
  use Guardian, otp_app: :event_sourcing_example

  def subject_for_token(account, _claims) do
    {:ok, account.id}
  end

  def resource_from_claims(claims) do
    account_id = claims["sub"]

    account =
      Amnesia.transaction do
        Database.Account.read(account_id)
      end

    {:ok, account}
  end
end
