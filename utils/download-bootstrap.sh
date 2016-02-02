#!/usr/bin/env sh
echo "Getting latest bootstrap url..."
URL=`curl -s 'https://api.github.com/repos/ooc-lang/rock/releases' | grep 'bootstrap-only' | grep 'browser_download_url' | head -1 | cut -d '"' -f 4`
if [ -z "${URL}" ]; then
  echo "Could not find latest bootstrap-only. Can you reach api.github.com ?"
  exit 1
fi

echo "Downloading from ${URL}"
curl -L ${URL} | tar xjm 1>/dev/null
