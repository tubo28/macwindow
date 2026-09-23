# macwindow

Rectangle で実際に使っている 左半分 / 右半分 / 最大化 の 3 つだけを、macOS 標準のアクセシビリティ API で置き換える小さな CLI。
常駐するのは LaunchAgent 1 つで、設定ファイルもメニューバーのアイコンも持たない。

| ショートカット | 動き |
| --- | --- |
| `⌃⌥←` | 左半分 |
| `⌃⌥→` | 右半分 |
| `⌃⌥↑` | 最大化 |

## 連打でディスプレイを歩く

同じショートカットをもう一度押すと、ウィンドウは隣のディスプレイの反対側の半分へ移る。
ディスプレイが 2 枚（A の右に B）で `⌃⌥→` を連打すると、半分のスロットを右へ 1 つずつ歩く。

```
A右半 → B左半 → B右半 → A左半 → A右半 → …     （⌃⌥← はこの逆）
1 枚: A右半 → A右半 → A右半 → …
```

連打と見なすのは、前回と同じアクションで、同じウィンドウが、前回置いた場所にまだある場合だけ。
手でウィンドウを動かしたあとは仕切り直しになる。

`⌃⌥↑` の連打はディスプレイを順に巡る。ここだけは Rectangle には無い動き。

## 使い方

```
swift build -c release
install -D -t ~/.local/bin .build/release/macwindow

macwindow install     # ログイン時からショートカットを待ち受ける常駐エージェントを登録
macwindow status      # 権限とエージェントの状態
macwindow uninstall   # エージェントを解除

macwindow left        # ショートカットを介さず手で動かす（動作確認用）
macwindow right
macwindow maximize
```

`macwindow left` などの単発の実行は、前回どこに置いたかを覚えていない
（プロセスがそのつど終わるため）。常に「1 回目の押下」として振る舞うので、
ディスプレイを歩くのは `macwindow watch`（＝常駐エージェント）の中だけになる。

## アクセシビリティ権限

他のアプリのウィンドウを動かすには **アクセシビリティ権限が要る**。
システム設定 → プライバシーとセキュリティ → アクセシビリティ に `~/.local/bin/macwindow` を登録する。
`macwindow install` は初回に許可を促すダイアログを出す。

TCC はバイナリを パス と コード署名 で見分ける。`swift build` するたび ad-hoc 署名が変わるので、
開発中は再ビルドのたびに登録し直す必要がある。これは避けられない。

## Rectangle との併用

同じキーを両方が握ると、どちらが動かしたのか分からなくなる。`macwindow install` したら
Rectangle 側の 3 つのショートカットを外すか、Rectangle ごとアンインストールする。

## 開発

```
swift build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

テストは swift-testing を使う。Command Line Tools の toolchain には `Testing` モジュールが入っていないため、
`swift test` だけは Xcode の toolchain を指す必要がある。

配置の判断はすべて純粋関数（`WindowPlacement` / `WindowFrame` / `Display`）にあり、
可変なのは「前回どこに何を置いたか」を持つ `WindowMover` だけ。
アクセシビリティ API と Carbon のホットキーはプロトコルの向こう側の薄い殻で、テストの対象外。

ウィンドウ操作の細部（最小サイズを持つアプリ、ディスプレイをまたぐ移動、`AXEnhancedUserInterface` を
立てている Electron / Office 系アプリ、応答しないアプリ）は
[rxhanson/Rectangle](https://github.com/rxhanson/Rectangle) の実装に倣っている。
