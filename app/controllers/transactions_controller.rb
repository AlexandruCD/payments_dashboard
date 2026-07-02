# frozen_string_literal: true

class TransactionsController < AuthenticatedController
  def index
    @transactions = scope.order(created_at: :desc).map { |transaction| TransactionPresenter.new(transaction) }
  end

  def show
    @transaction = TransactionPresenter.new(scope.find(params[:id]))
  end

  private

  # Admins see every transaction; merchants only ever see their own. A
  # merchant-role user without a linked Merchant (shouldn't happen, but not
  # impossible to end up with via the console) simply sees nothing.
  def scope
    return Transaction.all if current_user.admin?

    current_user.merchant&.transactions || Transaction.none
  end
end
