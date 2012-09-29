#!/bin/sh

xcodebuild

rm pdfshrink.zip

cd build/Release
zip -r ../../pdfshrink.zip PDFShrink.app
cd ../..
zip -u pdfshrink.zip ReadMe.rtf LiCENSE

cp pdfshrink.zip ~/Dropbox/Public/
