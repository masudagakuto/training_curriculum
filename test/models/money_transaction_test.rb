require 'test_helper'

class MoneyTransactionTest < ActiveSupport::TestCase
  # DB接続なしで動作するパースロジックのテスト

  test "「払った 田中 1000」を正しくパースできる" do
    t = MoneyTransaction.parse_from_line("払った 田中 1000")
    assert_not_nil t
    assert_equal "田中",  t.person
    assert_equal 1000,    t.amount
    assert_equal "paid",  t.transaction_type
  end

  test "「もらった 佐藤 500」を正しくパースできる" do
    t = MoneyTransaction.parse_from_line("もらった 佐藤 500")
    assert_not_nil t
    assert_equal "佐藤",     t.person
    assert_equal 500,        t.amount
    assert_equal "received", t.transaction_type
  end

  test "メモ付きでパースできる" do
    t = MoneyTransaction.parse_from_line("払った 田中 1000 ランチ代")
    assert_not_nil t
    assert_equal "ランチ代", t.note
  end

  test "全角スペースを正規化してパースできる" do
    t = MoneyTransaction.parse_from_line("払った　田中　1500")
    assert_not_nil t
    assert_equal "田中", t.person
    assert_equal 1500,   t.amount
  end

  test "不正なフォーマットは nil を返す" do
    assert_nil MoneyTransaction.parse_from_line("こんにちは")
    assert_nil MoneyTransaction.parse_from_line("")
    assert_nil MoneyTransaction.parse_from_line("払った 田中") # 金額なし
  end

  test "金額が0以下は nil を返す" do
    assert_nil MoneyTransaction.parse_from_line("払った 田中 0")
  end

  test "「受け取った」でもパースできる" do
    t = MoneyTransaction.parse_from_line("受け取った 山田 2000")
    assert_not_nil t
    assert_equal "received", t.transaction_type
    assert_equal 2000, t.amount
  end
end
