#!/bin/bash
# 停止NFT鲸鱼追踪项目
PID=$(ps -ef | grep nft-whale-tracker | grep -v grep | awk '{print $2}')
if [ -z "$PID" ]; then
  echo "没有发现正在运行的NFT鲸鱼追踪进程"
  exit 0
fi
echo "正在停止NFT鲸鱼追踪进程 $PID..."
kill $PID
echo "进程已停止"
