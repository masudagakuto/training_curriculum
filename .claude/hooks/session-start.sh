#!/bin/bash
set -euo pipefail

# リモート環境（Claude Code on the web）でのみ実行
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}"

echo "=== [session-start] MySQL クライアントライブラリのインストール ==="
if ! dpkg -s libmariadb-dev &>/dev/null; then
  # apt-get update はPPAの制限があるためスキップし、キャッシュから直接インストール
  apt-get install -y libmariadb-dev
fi

echo "=== [session-start] gem インストール開始 ==="
BUNDLE_ALLOW_ROOT=true bundle install --jobs 4 --retry 3

echo "=== [session-start] DB マイグレーション実行 ==="
# DB サーバーが起動していない場合はスキップ（接続エラーは無視）
if BUNDLE_ALLOW_ROOT=true bundle exec bin/rails db:migrate RAILS_ENV=development 2>&1; then
  echo "マイグレーション完了"
else
  echo "DBへの接続に失敗しました（DBサーバーが起動していない可能性があります）"
  echo "アプリ起動時に手動で 'bundle exec rails db:migrate' を実行してください"
fi

echo "=== [session-start] 完了 ==="
