class MoneyTransactionsController < ApplicationController

  # 一覧ページ
  def index
    @transactions = MoneyTransaction.recent
    @paid_total     = MoneyTransaction.paid.sum(:amount)
    @received_total = MoneyTransaction.received.sum(:amount)
    @balance        = @received_total - @paid_total
    @new_transaction = MoneyTransaction.new
  end

  # Webフォームからの登録
  def create
    @new_transaction = MoneyTransaction.new(transaction_params)
    if @new_transaction.save
      redirect_to money_transactions_path, notice: '記録しました'
    else
      @transactions   = MoneyTransaction.recent
      @paid_total     = MoneyTransaction.paid.sum(:amount)
      @received_total = MoneyTransaction.received.sum(:amount)
      @balance        = @received_total - @paid_total
      render :index
    end
  end

  # 削除
  def destroy
    MoneyTransaction.find(params[:id]).destroy
    redirect_to money_transactions_path, notice: '削除しました'
  end

  private

  def transaction_params
    params.require(:money_transaction).permit(:person, :amount, :transaction_type, :date, :note)
  end
end
