GlobalCategories - Movable Type プラグイン
=================

[English](README.md)

## 概要

特定のブログのカテゴリをグローバルカテゴリのように利用できます。

## 動作環境

* Movable Type 6

## インストール

1. [releases](https://github.com/bit-part/mt-plugin-GlobalCategories/releases)よりアーカイブファイルをダウンロードします。
1. ダウンロードしたファイルを展開します。
1. 展開したファイルをMovable Typeのプラグインディレクトリにアップロードします。

インストールしたディレクトリ構成は下記のようになります。

    $MT_HOME/
        plugins/
            GlobalCategories/

## 使い方

1. グローバルカテゴリを管理するためのブログAを作成します。
1. グローバルカテゴリの管理用ブログAの全般設定で `記事が含まれない場合でも、カテゴリ アーカイブを公開する` にチェックを入れて保存します。
1. グローバルカテゴリを使いたいブログBのプラグイン設定で、上記のグローバルカテゴリ管理ブログAのIDを指定します。
1. これでブログBの記事編集画面のカテゴリ選択欄にブログAのカテゴリが表示されるようになります。

## テンプレート

グローバルカテゴリに属する記事一覧を出力したい場合は、ブログAのカテゴリアーカイブで下記のようにして出力します。

```
<mt:CategoryLabel setvar="category_label" />
<mt:Entries include_blogs="all" category="$category_label">
   Do something
</mt:Entries>
```

---

MT::Lover::[bitpart](http://bit-part.net/)
