use Amnesia

alias Comeonin.Bcrypt

defdatabase Database do
  deftable Account,
           [{:id, autoincrement}, :email, :account_number, :password, :amount, :verified],
           type: :set,
           index: [:email, :account_number] do
    @type t :: %Account{
            id: non_neg_integer,
            email: String.t(),
            account_number: String.t(),
            password: String.t(),
            amount: integer,
            verified: boolean
          }

    defp generate_unique_account_number() do
      account_number = :rand.uniform(9999_9999_9999_9999) |> Integer.to_string()

      case get_account(%{account_number: account_number}) do
        {:error, _} -> account_number
        _ -> generate_unique_account_number()
      end
    end

    def create_new_account(email, password) do
      account_number = generate_unique_account_number()
      hash_password = Bcrypt.hashpwsalt(password)

      create_new_account(email, hash_password, account_number)
    end

    def create_new_account(email, hash_password, account_number, verify_code \\ nil) do
      with {:error, {"account not found", _}} <- get_account(%{email: email}),
           {:error, {"account not found", _}} <- get_account(%{account_number: account_number}) do
        new_account =
          %Account{
            email: email,
            account_number: account_number,
            password: hash_password,
            amount: 1_000_00,
            verified: false
          }
          |> Account.write()

        new_verify_code = Database.VerifyCode.new_record(new_account, verify_code)

        {:ok, {new_account, new_verify_code}}
      else
        _ ->
          {:error, "already exists an account using this e-mail and/or account number"}
      end
    end

    def verify_account(account, code) do
      case code == Database.VerifyCode.get_code_by_account(account) do
        true ->
          verified_account =
            %{account | verified: true}
            |> Account.write()

          Database.VerifyCode.delete_record(verified_account)

          {:ok, verified_account}

        false ->
          {:error, "wrong verify code"}
      end
    end

    def get_account(%{email: by_email}) do
      accounts_by_email = where(email == by_email)

      case Amnesia.Selection.values(accounts_by_email) do
        [account] -> {:ok, account}
        [] -> {:error, {"account not found", %{email: by_email}}}
      end
    end

    def get_account(%{account_number: by_account_number, plain_text_password: plain_text_password}) do
      with {:ok, account} <- get_account(%{account_number: by_account_number}),
           true <- Bcrypt.checkpw(plain_text_password, account.password) do
        {:ok, account}
      else
        _ -> {:error, {"account not found", %{account_number: by_account_number}}}
      end
    end

    def get_account(%{account_number: by_account_number}) do
      accounts_by_account_number = where(account_number == by_account_number)

      case Amnesia.Selection.values(accounts_by_account_number) do
        [account] -> {:ok, account}
        [] -> {:error, {"account not found", %{account_number: by_account_number}}}
      end
    end

    def get_account!(%{account_number: by_account_number}) do
      case get_account(%{account_number: by_account_number}) do
        {:ok, account} -> account
        _ -> raise ArgumentError, message: "account not found"
      end
    end

    defp check_verified(account) do
      case account.verified do
        true ->
          {:ok, true}

        false ->
          {:error, {"account not verified", account}}
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
      with {:ok, from_account} <- get_account(%{account_number: from_account_number}),
           {:ok, true} <- check_money(from_account, amount),
           {:ok, to_account} <- get_account(%{account_number: to_account_number}),
           {:ok, true} <- check_verified(from_account),
           {:ok, true} <- check_verified(to_account) do
        from_account_new_amount =
          %{from_account | amount: from_account.amount - amount}
          |> Account.write()

        %{to_account | amount: to_account.amount + amount}
        |> Account.write()

        {:ok, from_account_new_amount}
      else
        err -> err
      end
    end

    def withdraw(account, amount) do
      with {:ok, true} <- check_money(account, amount),
           {:ok, true} <- check_verified(account) do
        account_new_amount =
          %{account | amount: account.amount - amount}
          |> Account.write()

        {:ok, account_new_amount}
      else
        err -> err
      end
    end

    def all() do
      Account.foldl([], &[Account.coerce(&1) | &2])
    end
  end

  deftable VerifyCode, [{:id, autoincrement}, :account_id, :code],
    type: :set,
    index: [:account_id] do
    @type t :: %VerifyCode{
            id: non_neg_integer,
            account_id: non_neg_integer,
            code: String.t()
          }

    def new_record(account, nil) do
      %VerifyCode{account_id: account.id, code: SecureRandom.urlsafe_base64()}
      |> VerifyCode.write()
    end

    def new_record(account, verify_code) do
      %VerifyCode{account_id: account.id, code: verify_code}
      |> VerifyCode.write()
    end

    def delete_record(account) do
      get_record_by_account(account)
      |> VerifyCode.delete()
    end

    defp get_record_by_account(account) do
      where(account_id == account.id)
      |> Amnesia.Selection.values()
      |> List.first()
    end

    def get_code_by_account(account) do
      get_record_by_account(account)
      |> Map.fetch!(:code)
    end
  end
end
