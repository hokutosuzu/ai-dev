# Playwright 導入方針メモ

## 現在のシステム構成

- Frontend: Next.js
- Backend: NestJS
- DB: MySQL 8系
- インフラ:
  - CloudFront
  - WAF
  - ALB
  - ECS
- 各 repository ごとに Docker image を build し、ECR へ push している
- frontend / backend は repository 分離構成

---

# 当初の検討内容

Playwright を用いた E2E テスト導入を検討。

最初は以下を考えていた。

- Playwright 専用実行環境を ECS / EC2 で別途持つ
- GitHub Actions から Playwright 実行環境を起動
- 実サーバー（CloudFront -> WAF -> ALB -> ECS）を対象に E2E 実施
- GitHub Pages にレポート出力
- Playwright 結果を品質ゲート化

---

# 検討の中で見えてきた問題

## 実環境 E2E の運用コスト

以下の問題が発生しやすい。

- flaky test
- staging DB 汚染
- テストデータ競合
- deploy timing 問題
- CloudFront cache
- 外部API影響
- ECS 起動待ち
- 原因切り分け難易度上昇

特に「実DBを使う E2E」が怖い。

---

# 現時点の方針

## Playwright の役割を限定する

Playwright は以下用途に限定する。

- 主要導線のスモークテスト
- deploy artifact の最低限確認
- 致命的崩壊の早期検知

例:

- ログイン
- 一覧表示
- CRUD 最低限
- JSエラー検知

---

# 最終的な品質担保

複雑な業務確認や詳細確認は手動テストで担保する。

つまり以下の役割分担。

| 種類 | 役割 |
|---|---|
| Unit Test | ロジック |
| Integration Test | API整合性 |
| Playwright | 主要導線スモーク |
| 手動試験 | 業務観点・最終保証 |

---

# 実環境 E2E は現時点では見送る

当初は staging 実環境 E2E を考えていたが、
現時点では運用コストと複雑性が高いため見送る。

まずは Compose 上の仮想環境で Playwright を実行する。

---

# 現在の導入方針

## Step1: ローカル Docker Compose 構築

Compose 上で以下を起動。

- frontend
- backend
- mysql
- playwright

---

# Playwright 実行イメージ

Playwright は Node.js 上で動作し、
headless browser を自動操作する。

Playwright コンテナから frontend コンテナへアクセスする。

例:

```ts
await page.goto('http://frontend:3000/login');
```

localhost ではなく container name 通信を使用。

---

# 想定 docker-compose 構成

```yaml
services:
  frontend:
    build: ./frontend

  backend:
    build: ./backend

  mysql:
    image: mysql:8

  playwright:
    image: mcr.microsoft.com/playwright:v1.54.0-noble
```

---

# 想定 Playwright テスト例

```ts
test('login', async ({ page }) => {
  await page.goto('http://frontend:3000/login');

  await page.fill('input[name=email]', 'test@example.com');
  await page.fill('input[name=password]', 'password');

  await page.click('button[type=submit]');

  await expect(page).toHaveURL('/dashboard');
});
```

---

# CI/CD 方針

将来的には GitHub Actions 上で
Compose をそのまま起動して Playwright 実行予定。

イメージ:

```yaml
- docker compose up -d
- docker compose run playwright
```

---

# Repository 構成方針

将来的には Playwright / E2E を独立 repository 化する可能性あり。

理由:

- frontend / backend repository が分離されているため
- deploy artifact 単位で検証したいため
- ECR image 組み合わせ検証をしたいため

ただし現時点ではまずローカル導入を優先。

---

# 現在のゴール

まずは以下を成功させたい。

- Docker Compose 上で frontend/backend/mysql/playwright 起動
- Playwright から Next.js 画面へアクセス
- 最低限のログインテスト成功
- ローカルで安定実行できる状態にする

その後 GitHub Actions 化を検討する。