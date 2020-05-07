#!/bin/bash

GITLAB_PATH=$1
GITHUB_PATH=$2

VERSION=$3
BRANCH=$4

######################
# Podspec version
######################

cd ${GITHUB_PATH}
git checkout ${BRANCH}

rm -rf ${GITHUB_PATH}/*
cp -R ${GITLAB_PATH}/* .

git add .
git commit -m "Release ${VERSION}"
git push -u origin ${BRANCH}

exit 0
