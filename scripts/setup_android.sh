#!/usr/bin/env bash

set -eu

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SDK_VERSION="2.1.0"

rm -rf "${SCRIPT_DIR}/../android/libs"
mkdir -p "${SCRIPT_DIR}/../android/libs"

pushd "${SCRIPT_DIR}/../android/libs"
wget "https://switchboard-sdk-public.s3.amazonaws.com/builds/release/${SDK_VERSION}/android/SwitchboardSDK.aar"
wget "https://switchboard-sdk-public.s3.amazonaws.com/builds/release/${SDK_VERSION}/android/SwitchboardVoicemod.aar"
wget "https://switchboard-sdk-public.s3.amazonaws.com/builds/release/${SDK_VERSION}/android/SwitchboardRNNoise.aar"
popd
