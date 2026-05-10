GITHUB_ORG := hokutosuzu

.PHONY: setup pull-all up down restart test logs

# 初回セットアップ：各リポジトリをクローン
setup:
	git clone git@github.com:$(GITHUB_ORG)/ai-dev-api.git api
	git clone git@github.com:$(GITHUB_ORG)/ai-dev-web.git web
	git clone git@github.com:$(GITHUB_ORG)/ai-dev-e2e.git e2e

# 全リポジトリを最新に更新
pull-all:
	git pull
	cd api && git pull
	cd web && git pull
	cd e2e && git pull

# Docker Compose 起動
up:
	docker compose up -d

# Docker Compose 停止
down:
	docker compose down

# Docker Compose 再起動
restart:
	docker compose restart

# E2E テスト実行
test:
	docker compose --profile test run --rm playwright

# ログ確認（サービス名省略時は全サービス）
# 例: make logs s=api
logs:
	docker compose logs -f $(s)
