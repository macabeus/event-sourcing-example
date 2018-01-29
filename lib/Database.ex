use Amnesia

defdatabase Database do
  deftable Account, [{:id, autoincrement}, :email, :account_number, :password, :amount],
    type: :set, index: [:email, :account_number] do

      @type t :: %Account{
        id: non_neg_integer,
        email: String.t,
        account_number: String.t,
        password: String.t,
        amount: integer
      }

      def create_new_account(email, password) do
        # TODO: Check if the email and account_number is unique
        # TODO: Send the e-mail to validade this account
        %Account{email: email, account_number: 1, password: password, amount: 1_000_00}
        |> Account.write
      end
  end
end
