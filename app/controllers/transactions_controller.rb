# frozen_string_literal: true

class TransactionsController < AuthenticatedController
  def index
    @transactions = scope.order(created_at: :desc).map { |transaction| TransactionPresenter.new(transaction) }
  end

  def show
    @transaction = TransactionPresenter.new(scope.find(params[:id]))
  end

  private

  # Admins see every transaction; merchant users see their own.
  def scope
    return Transaction.all if current_user.admin?

    current_user.merchant.transactions
  end
end
