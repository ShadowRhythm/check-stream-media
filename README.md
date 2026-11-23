# Introduce
The code for this script to detect streaming media unlocking is all from the open source project [https://github.com/lmc999/RegionRestrictionCheck](https://github.com/lmc999/RegionRestrictionCheck) and [https://gitlab.com/fscarmen/warp_unlock](https://gitlab.com/fscarmen/warp_unlock), and the open source protocol is AGPL-3.0. This script is open source as required by the open source license. Thanks to the original authors @lmc999, @fscarmen and everyone who made the pull request for this project for their contributions.

# How to use

### 1. 流媒体检测与 WebAPI 上报 (csm.sh)
用于单次检测或配合 SSPanel-UIM / NeXT-Panel 定时上报节点流媒体解锁状态：
```bash
wget https://raw.githubusercontent.com/ShadowRhythm/check-stream-media/main/csm.sh
bash csm.sh
```

### 2. Cloudflare WARP 流媒体 / Google 解锁守护刷 IP (unlock.sh)
专为 WARP 节点解锁打造的守护脚本，支持 Netflix、Disney+、ChatGPT、Google（含免人机验证与防送中判定），遇到不解锁自动更换/刷 WARP IP：
```bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ShadowRhythm/check-stream-media/main/unlock.sh
bash unlock.sh
```

快捷参数示例：
```bash
# 简体中文、新加坡地区、检测并解锁 Netflix 与 Google、模式 1 (定时 5 分钟检查并刷 IP)
bash unlock.sh -C -A sg -N ng -M 1
```
