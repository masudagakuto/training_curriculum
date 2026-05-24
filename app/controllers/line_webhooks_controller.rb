class LineWebhooksController < ApplicationController
  # LINE のWebhookはCSRFトークンを送らないため除外
  skip_before_action :verify_authenticity_token

  def callback
    body    = request.body.read
    sig     = request.env['HTTP_X_LINE_SIGNATURE']

    # 署名検証（LINE_CHANNEL_SECRET が設定されている場合）
    if ENV['LINE_CHANNEL_SECRET'].present?
      unless client.validate_signature(body, sig)
        head :bad_request
        return
      end
    end

    events = client.parse_events_from(body)

    events.each do |event|
      next unless event.is_a?(Line::Bot::Event::Message)
      next unless event.message['type'] == 'text'

      text         = event.message['text']
      line_user_id = event['source']['userId']

      handle_message(text, line_user_id, event['replyToken'])
    end

    head :ok
  end

  private

  def handle_message(text, line_user_id, reply_token)
    normalized = text.to_s.strip.gsub('　', ' ')

    # 残高確認コマンド
    if normalized.match?(/\A残高(確認)?/)
      reply_balance(reply_token)
      return
    end

    # 一覧コマンド
    if normalized.match?(/\A(一覧|りれき|履歴)/)
      reply_history(reply_token)
      return
    end

    # お金の記録パース
    transaction = MoneyTransaction.parse_from_line(text, line_user_id: line_user_id)

    if transaction&.save
      reply_message(reply_token, "✅ 記録しました！\n#{transaction.summary}\n\n「残高確認」で収支を確認できます")
    elsif transaction
      reply_message(reply_token, "❌ 保存に失敗しました。もう一度お試しください。")
    else
      reply_message(reply_token, help_text)
    end
  end

  def reply_balance(reply_token)
    paid_total     = MoneyTransaction.paid.sum(:amount)
    received_total = MoneyTransaction.received.sum(:amount)
    balance        = received_total - paid_total

    balance_str = balance >= 0 ? "+¥#{balance}" : "-¥#{balance.abs}"
    text = "💰 収支まとめ\n" \
           "支払い合計: ¥#{paid_total}\n" \
           "受取り合計: ¥#{received_total}\n" \
           "収支: #{balance_str}"

    reply_message(reply_token, text)
  end

  def reply_history(reply_token)
    records = MoneyTransaction.recent.limit(10)

    if records.empty?
      reply_message(reply_token, "まだ記録がありません。")
      return
    end

    lines = records.map(&:summary)
    reply_message(reply_token, "📋 最近の記録\n" + lines.join("\n"))
  end

  def reply_message(reply_token, text)
    return unless ENV['LINE_CHANNEL_ACCESS_TOKEN'].present?

    client.reply_message(reply_token, { type: 'text', text: text })
  end

  def client
    @client ||= Line::Bot::Client.new do |config|
      config.channel_secret       = ENV['LINE_CHANNEL_SECRET'] || ''
      config.channel_token        = ENV['LINE_CHANNEL_ACCESS_TOKEN'] || ''
    end
  end

  def help_text
    <<~TEXT
      💡 使い方
      ─────────────────
      払った <相手> <金額>
      例: 払った 田中 1000

      もらった <相手> <金額>
      例: もらった 佐藤 500

      メモも追加できます:
      払った 田中 1000 ランチ代

      ─────────────────
      「残高確認」→ 収支を表示
      「履歴」→ 最近の記録を表示
    TEXT
  end
end
