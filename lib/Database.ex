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
  end
end
