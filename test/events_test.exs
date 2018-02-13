defmodule EventSourcingExampleTest.Events do
  use Amnesia
  use ExUnit.Case

  alias Comeonin.Bcrypt

  alias EventSourcingExample.Bus
  alias EventSourcingExample.Event.MoneyTransfer
  alias EventSourcingExample.Event.NewAccount
  alias EventSourcingExample.Event.VerifyAccount
  alias EventSourcingExample.Event.Withdraw

  # New Account tests

  test "Should create accounts" do
    hash_password = Bcrypt.hashpwsalt("abc123")

    result =
      Bus.forward_event(
        [
          %NewAccount{
            email: "foo@email.com",
            password: hash_password,
            account_number: "1",
            verify_code: "foo"
          },
          %NewAccount{
            email: "bar@email.com",
            password: hash_password,
            account_number: "2",
            verify_code: "foo"
          },
          %NewAccount{
            email: "baz@email.com",
            password: hash_password,
            account_number: "3",
            verify_code: "foo"
          }
        ],
        [:do_not_log, :do_not_send_email]
      )

    all_accounts = Amnesia.transaction(&Database.Account.all/0)

    all_verify_code =
      Amnesia.transaction do
        Database.VerifyCode.foldl([], &[&1 | &2])
      end

    assert :ok == result
    assert 3 == length(all_accounts)
    assert 3 == length(all_verify_code)
  end

  test "Should fail when creating account using same e-mail" do
    result =
      Bus.forward_event(
        [
          %NewAccount{
            email: "foo@email.com",
            password: "abc123",
            account_number: "4",
            verify_code: "foo"
          }
        ],
        [:do_not_log, :do_not_send_email]
      )

    assert {:error, [{"already exists an account using this e-mail and/or account number", _}]} =
             result
  end

  test "Should fail when creating account using same account number" do
    result =
      Bus.forward_event(
        [
          %NewAccount{
            email: "qux@email.com",
            password: "abc123",
            account_number: "3",
            verify_code: "foo"
          }
        ],
        [:do_not_log, :do_not_send_email]
      )

    assert {:error, [{"already exists an account using this e-mail and/or account number", _}]} =
             result
  end

  # Verify tests

  test "Should verify accounts" do
    result =
      Bus.forward_event(
        [
          %VerifyAccount{account_number: "1", code: "foo"},
          %VerifyAccount{account_number: "2", code: "foo"}
        ],
        [:do_not_log, :do_not_send_email]
      )

    assert :ok == result
  end

  test "Should fail when trying verify an invalid account number" do
    result =
      Bus.forward_event(
        [
          %VerifyAccount{account_number: "invalid", code: "foo"}
        ],
        [:do_not_log, :do_not_send_email]
      )

    assert {:error, [{{"account not found", %{account_number: "invalid"}}, _}]} = result
  end

  test "Should fail when trying verify using an invalid code" do
    result =
      Bus.forward_event(
        [
          %VerifyAccount{account_number: "3", code: "invalid"}
        ],
        [:do_not_log, :do_not_send_email]
      )

    assert {:error, [{"wrong verify code", _}]} = result
  end

  # Withdraw tests

  test "Should can withdraw" do
    result =
      Bus.forward_event(
        [
          %Withdraw{account_number: "1", amount: 100_00}
        ],
        [:do_not_log, :do_not_send_email]
      )

    account =
      Amnesia.transaction do
        Database.Account.get_account!(%{account_number: "1"})
      end

    assert :ok == result
    assert 900_00 == account.amount
  end

  test "Should fail when trying withdraw more than have on account" do
    result =
      Bus.forward_event(
        [
          %Withdraw{account_number: "1", amount: 1_000_00}
        ],
        [:do_not_log, :do_not_send_email]
      )

    assert {:error, [{{"account does not have enough money", _}, _}]} = result
  end

  test "Should fail when trying withdraw using a not verify account" do
    result =
      Bus.forward_event(
        [
          %Withdraw{account_number: "3", amount: 100_00}
        ],
        [:do_not_log, :do_not_send_email]
      )

    assert {:error, [{{"account not verified", _}, _}]} = result
  end

  test "Should fail when trying withdraw using an invalid account number" do
    result =
      Bus.forward_event(
        [
          %Withdraw{account_number: "invalid", amount: 100_00}
        ],
        [:do_not_log, :do_not_send_email]
      )

    assert {:error, [{{"account not found", _}, _}]} = result
  end

  # MoneyTransfer tests

  test "Should can transfer money" do
    result =
      Bus.forward_event(
        [
          %MoneyTransfer{from_account_number: "1", to_account_number: "2", amount: 100_00}
        ],
        [:do_not_log, :do_not_send_email]
      )

    {account_1, account_2} =
      Amnesia.transaction do
        {
          Database.Account.get_account!(%{account_number: "1"}),
          Database.Account.get_account!(%{account_number: "2"})
        }
      end

    assert :ok == result
    assert 800_00 == account_1.amount
    assert 1_100_00 == account_2.amount
  end

  test "Should fail when trying transfer more than have on account" do
    result =
      Bus.forward_event(
        [
          %MoneyTransfer{from_account_number: "1", to_account_number: "2", amount: 1_000_00}
        ],
        [:do_not_log, :do_not_send_email]
      )

    assert {:error, [{{"account does not have enough money", _}, _}]} = result
  end

  test "Should fail when trying transfer from an invalid account number" do
    result =
      Bus.forward_event(
        [
          %MoneyTransfer{from_account_number: "invalid", to_account_number: "2", amount: 100_00}
        ],
        [:do_not_log, :do_not_send_email]
      )

    assert {:error, [{{"account not found", %{account_number: "invalid"}}, _}]} = result
  end

  test "Should fail when trying transfer to an invalid account number" do
    result =
      Bus.forward_event(
        [
          %MoneyTransfer{from_account_number: "1", to_account_number: "invalid", amount: 100_00}
        ],
        [:do_not_log, :do_not_send_email]
      )

    assert {:error, [{{"account not found", %{account_number: "invalid"}}, _}]} = result
  end
end
