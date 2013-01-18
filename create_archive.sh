#!/bin/sh

# アプリケーションをビルド

xcodebuild

# ドキュメントを RTF 形式に

pandoc -s README.md -o ReadMe.rtf
pandoc -s CHANGES.md -o Changes.rtf

# 古い Zip ファイルを削除

rm pdfshrink.zip

# リリース用 Zip ファイルを生成

cd build/Release
zip -r ../../pdfshrink.zip PDFShrink.app
cd ../..
zip -u pdfshrink.zip ReadMe.rtf Changes.rtf LICENSE

# リリース用 Zip ファイルを公開

cp pdfshrink.zip ~/Dropbox/Public/
