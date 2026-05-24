class CreateMoneyTransactions < ActiveRecord::Migration[6.0]
  def change
    create_table :money_transactions do |t|
      t.string  :person,           null: false  # 相手の名前
      t.integer :amount,           null: false  # 金額（円）
      t.string  :transaction_type, null: false  # "paid"（払った）or "received"（もらった）
      t.date    :date,             null: false  # 取引日
      t.string  :note                          # メモ（任意）
      t.string  :line_user_id                  # LINEユーザーID

      t.timestamps
    end
  end
end
