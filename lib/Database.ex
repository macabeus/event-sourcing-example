use Amnesia

require OK

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

      defp generate_unique_account_number() do
        account_number = :rand.uniform(9999_9999_9999_9999) |> Integer.to_string

        case get_account(%{account_number: account_number}) do
          {:error, _} -> account_number
          _ -> generate_unique_account_number()
        end
      end

      def create_new_account(email, password) do
        account_number = generate_unique_account_number()

        create_new_account(email, password, account_number)
      end

      def create_new_account(email, password, account_number) do
        # TODO: Send the e-mail to validade this account

        with {:ok, _} <- get_account(%{email: email}),
             {:ok, _} <- get_account(%{account_number: account_number})
        do
          {:error, "already exists an account using this e-mail and/or account number"}
        else
          _ ->
            new_account = %Account{
              email: email,
              account_number: account_number,
              password: password, amount: 1_000_00}
            |> Account.write

            {:ok, new_account}
        end
      end

      def get_account(%{account_number: by_account_number}) do
        accounts_by_account_number = where(account_number == by_account_number)

        case Amnesia.Selection.values(accounts_by_account_number) do
          [account] -> {:ok, account}
          [] -> {:error, {"account not found", %{account_number: by_account_number}}}
        end
      end

      def get_account(%{email: by_email}) do
        accounts_by_email = where(email == by_email)

        case Amnesia.Selection.values(accounts_by_email) do
          [account] -> {:ok, account}
          [] -> {:error, {"account not found", %{email: by_email}}}
        end
      end

      defp check_money(account, amount) do
        case account.amount > amount do
          true ->
            {:ok, true}

          false ->
            {:error, {"account does not have enough money", account}}
        end
      end

      def money_transfer(from_account_number, to_account_number, amount) do
        OK.try do
          from_account <- get_account(%{account_number: from_account_number})
          true         <- check_money(from_account, amount)
          to_account   <- get_account(%{account_number: to_account_number})
        after
          from_account_new_amount =
            %{from_account | amount: from_account.amount - amount}
            |> Account.write

          %{to_account | amount: to_account.amount + amount}
          |> Account.write

          {:ok, from_account_new_amount}
        rescue
          err -> {:error, err}
        end
      end
  end
end
