#!/usr/bin/env bash

VERSION=$(git describe --tags --abbrev=0)
wget https://github.com/tcnksm/ghr/releases/download/v0.14.0/ghr_v0.14.0_linux_amd64.tar.gz
tar -xvzf ghr_*.tar.gz
mv ghr_*_amd64 ghr

ln -s build/linux/x64/release/bundle/ chat-apropo
zip linux_x64.zip -r chat-apropo/*

mkdir -p ghrelease
mv *.zip ghrelease/

mv build/app/outputs/apk/release/app-armeabi-v7a-release.apk ghrelease/
mv build/app/outputs/apk/release/app-arm64-v8a-release.apk ghrelease/
mv build/app/outputs/apk/release/app-x86_64-release.apk ghrelease/

echo "RELEASE VERSION $VERSION"
./ghr/ghr -t ${GITHUB_TOKEN} -u ${CIRCLE_PROJECT_USERNAME} -r ${CIRCLE_PROJECT_REPONAME} -c ${CIRCLE_SHA1} -delete ${VERSION} ./ghrelease/
