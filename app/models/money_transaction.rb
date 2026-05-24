class MoneyTransaction < ApplicationRecord
  PAID     = 'paid'.freeze     # 払った
  RECEIVED = 'received'.freeze # もらった

  validates :person,           presence: true
  validates :amount,           presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :transaction_type, presence: true, inclusion: { in: [PAID, RECEIVED] }
  validates :date,             presence: true

  scope :paid,     -> { where(transaction_type: PAID) }
  scope :received, -> { where(transaction_type: RECEIVED) }
  scope :recent,   -> { order(date: :desc, created_at: :desc) }

  # LINEのメッセージテキストを解析して MoneyTransaction を返す
  # 対応フォーマット:
  #   払った <相手> <金額>           例: 払った 田中 1000
  #   もらった <相手> <金額>         例: もらった 佐藤 500
  #   払った <相手> <金額> <メモ>    例: 払った 田中 1000 ランチ代
  #   残高確認                       → nil を返す（一覧取得用コマンド）
  def self.parse_from_line(text, line_user_id: nil)
    text = text.to_s.strip
    # スペース・全角スペースを正規化
    text = text.gsub('　', ' ').gsub(/\s+/, ' ')

    if text.match?(/\A(払った|はらった)/i)
      parts = text.split(' ', 5)
      # parts[0] = "払った", parts[1] = 相手, parts[2] = 金額, parts[3] = メモ（省略可）
      return nil if parts.length < 3

      person = parts[1]
      amount = parts[2].to_s.gsub(/[^0-9]/, '').to_i
      note   = parts[3..].join(' ') if parts.length > 3

      return nil unless amount > 0

      new(
        person:           person,
        amount:           amount,
        transaction_type: PAID,
        date:             Date.today,
        note:             note,
        line_user_id:     line_user_id
      )

    elsif text.match?(/\A(もらった|受け取った)/i)
      parts = text.split(' ', 5)
      return nil if parts.length < 3

      person = parts[1]
      amount = parts[2].to_s.gsub(/[^0-9]/, '').to_i
      note   = parts[3..].join(' ') if parts.length > 3

      return nil unless amount > 0

      new(
        person:           person,
        amount:           amount,
        transaction_type: RECEIVED,
        date:             Date.today,
        note:             note,
        line_user_id:     line_user_id
      )
    end
  end

  # 取引の表示テキスト
  def summary
    type_label = transaction_type == PAID ? '払った' : 'もらった'
    base = "#{date.strftime('%m/%d')} #{person}に#{type_label} ¥#{amount.to_s(:delimited)}"
    note.present? ? "#{base}（#{note}）" : base
  end

  # 収支合計（受け取り - 支払い）
  def self.balance
    received.sum(:amount) - paid.sum(:amount)
  end
end
