# この駅で降りタイマー (KONO EKI DE ORITIMER)

電車の乗り過ごし防止アプリ。目的地の駅に近づいたことをジオフェンスで検知し、バイブレーションや通知で知らせる Flutter 製モバイルアプリ。

---

## 主な機能

- **ジオフェンス監視**：目的駅の緯度・経度を中心に領域を設定し、接近を自動検知
- **アラート通知**：ローカル通知 + バイブレーション + 音量制御で乗り過ごしを防止
- **マルチゴール設定**：複数の目的駅をあらかじめ登録し、番号で切り替えて使用可能
- **パターンルート表示**：路線パターンを一覧表示し、乗車区間を視覚的に確認
- **東京都内の路線・駅データ取得**：HTTP API 経由でリアルタイムに路線・駅情報を取得
- **地図表示**：OpenStreetMap (flutter_map) で現在地と目的駅を地図上に表示
- **設定の永続化**：SharedPreferences で選択駅やマルチゴール設定を保存・復元

---

## 技術スタック

| 分類 | 技術 |
|------|------|
| フレームワーク | Flutter / Dart |
| 状態管理 | Riverpod (hooks_riverpod / flutter_riverpod / riverpod_annotation) |
| コード生成 | Freezed / json_serializable / build_runner |
| ジオフェンス | native_geofence |
| 位置情報 | geolocator / permission_handler |
| 通知 | flutter_local_notifications |
| バイブレーション | vibration / flutter_volume_controller |
| 地図 | flutter_map + latlong2 (OpenStreetMap) |
| グラフ | fl_chart |
| HTTP 通信 | http + flutter_dotenv (環境変数管理) |
| データ永続化 | shared_preferences |
| UI | flutter_carousel_slider / dotted_line / cached_network_image |
| スクロール | scroll_to_index / scrollable_positioned_list |
| アイコン | font_awesome_flutter |
| テーマ | ダークテーマ固定 |
| 向き | 縦向き固定（portraitUp） |

---

## アーキテクチャ

```
lib/
├── main.dart                          # エントリーポイント・アプリルート
├── const/                             # 定数定義
├── controllers/
│   ├── controllers_mixin.dart         # コントローラー統合 Mixin
│   ├── _get_data/
│   │   └── tokyo_train/
│   │       └── tokyo_train.dart       # 路線・駅データ取得 Riverpod ノーティファイア
│   └── app_param/
│       └── app_param.dart             # アプリ状態管理 Riverpod ノーティファイア
├── data/
│   └── http/
│       ├── client.dart                # HTTP クライアント
│       └── path.dart                  # API パス定義
├── model/
│   └── tokyo_train_model.dart         # TokyoTrainModel / TokyoStationModel
├── screens/
│   ├── home_screen.dart               # メイン画面
│   ├── components/
│   │   ├── multi_goal_display_alert.dart   # マルチゴール一覧表示ダイアログ
│   │   ├── multi_goal_setting_alert.dart   # マルチゴール設定ダイアログ
│   │   └── pattern_route_display_alert.dart # パターンルート表示ダイアログ
│   └── parts/
│       ├── error_dialog.dart          # エラーダイアログ
│       └── oritimer_dialog.dart       # 降りタイマーダイアログ
├── extensions/                        # 拡張メソッド
└── utility/
    └── shared_preferences_service.dart # SharedPreferences ラッパー
```

---

## データモデル

### TokyoTrainModel
| フィールド | 型 | 説明 |
|-----------|-----|------|
| trainNumber | int | 路線番号 |
| trainName | String | 路線名 |
| station | List\<TokyoStationModel\> | 駅一覧 |

### TokyoStationModel
| フィールド | 型 | 説明 |
|-----------|-----|------|
| id | String | 駅 ID |
| stationName | String | 駅名 |
| address | String | 住所 |
| lat | double | 緯度 |
| lng | double | 経度 |

---

## アプリ状態管理 (AppParamState)

| 状態 | 型 | 説明 |
|------|-----|------|
| isSetStation | bool | 駅監視の ON/OFF |
| selectedMultiNumber | int | 選択中のマルチゴール番号 |
| selectedStationName | String | 選択中の駅名 |
| selectedPatternDispString | String | 表示中のパターン文字列 |

---

## API エンドポイント

| エンドポイント | 説明 |
|--------------|------|
| `getTokyoTrainStation` | 東京都内の路線・駅一覧を取得 |

接続先 URL は `.env` ファイルで管理。

---

## セットアップ

### 前提条件
- Flutter SDK 3.x 以上
- Dart SDK ^3.10.8

### インストール

```bash
git clone https://github.com/toyotarou/flutter_konoeki_de_oritimer.git
cd flutter_konoeki_de_oritimer
flutter pub get
```

### 環境変数設定

プロジェクトルートに `.env` ファイルを作成し、API ベース URL を設定：

```env
API_BASE_URL=https://your-api-server.example.com/api/
```

### コード生成

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 実行

```bash
flutter run
```

---

## 必要な権限

| 権限 | 用途 |
|------|------|
| 位置情報（常時） | ジオフェンス監視・現在地取得 |
| 通知 | ローカル通知送信 |
| バイブレーション | アラート時の振動 |

---

## ジオフェンス鳴動時の全画面ダイアログ

満員電車でも操作しやすいよう、ジオフェンス到達時にホーム画面全体を覆う大きなダイアログを表示する機能を追加。

### 動作フロー

1. ジオフェンス発火 → `geofenceCallback`（バックグラウンド isolate）が通知・バイブレーションを開始
2. `IsolateNameServer` 経由で UI isolate へ即時通知
3. `HomeScreen` の `ReceivePort` がメッセージを受信 → 全画面ダイアログを表示
4. 画面をタップ → **リスト上の最初の目的地（キーが最小の multiGoal）のみ**停止・バイブレーション終了

アプリがバックグラウンドの場合は `SendPort` が `null` になるため、通知のみ届く（従来通り）。

### ファイル構成

| ファイル | 変更内容 |
|---------|---------|
| `lib/utility/functions.dart` | `geofenceCallback` に `IsolateNameServer.lookupPortByName` で UI へ送信する処理を追加 |
| `lib/screens/home_screen.dart` | `ReceivePort` 登録・ダイアログ表示・最初のゴール停止ロジックを追加。起動時のキーボード抑制のためダミー `FocusNode` を配置 |
| `lib/screens/parts/geofence_alert_dialog.dart` | 全画面アラートダイアログウィジェット（新規作成） |

### キーボード対策

- ホーム画面の Column 先頭に `Focus(autofocus: true)` + ダミー `FocusNode` を配置し、起動時に TextField へフォーカスが当たらないようにしている
- ジオフェンス発火時は `_dummyFocusNode.requestFocus()` でフォーカスをダミーノードへ移してからダイアログを表示
