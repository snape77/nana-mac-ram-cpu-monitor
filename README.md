# nana mac RAM / CPU monitor

一个轻量原生 macOS 菜单栏小工具：上行显示 RAM 警戒指数，下行显示 CPU 使用率。白色数字搭配 50% 透明度的绿色、黄色或红色背景，占用 36 pt 菜单栏宽度。

## 下载与安装

在 [Releases](https://github.com/snape77/nana-mac-ram-cpu-monitor/releases/latest) 下载 Apple Silicon 安装包，解压后将 **RAM Monitor.app** 放入“应用程序”并打开。需要 macOS 13 或更新版本。

程序使用本地临时签名，未经过 Apple 公证。首次打开可能被 macOS 拦截；确认来源后，可在“系统设置 → 隐私与安全性”中选择“仍要打开”，也可以自行从源码构建。

更新前请从菜单退出旧版本。v0.2.2 使用通用应用标识，旧版的刷新频率设置不会迁移，首次默认为 5 秒。

## 显示与设置

| 项目 | 含义与颜色 |
| --- | --- |
| 上行 RAM | 警戒指数，100% 是黄色警戒参考线，可超过 100% |
| RAM 背景 | 跟随 macOS 的正常 / 警告 / 严重压力状态，并非按显示数值硬切换 |
| 下行 CPU | 全机 CPU 使用率，范围 0–100%，为两次采样之间的平均值 |
| CPU 背景 | ≤80% 绿色，>80% 黄色，>90% 红色；阈值使用未四舍五入的数值 |
| 灰色 --% | 数据暂不可用，或 CPU 正在等待第二次采样 |

点击菜单栏数字可查看已用内存、压缩内存、交换空间、CPU 使用率，并选择 **1 秒、5 秒（默认）、10 秒、15 秒** 刷新。选择会保存在本机，下次启动沿用。菜单也提供立即刷新、打开活动监视器和退出。

RAM 数字是透明公开的压缩压力估算，不是 RAM 已用比例，也不是活动监视器提供的官方百分比：

```text
原始估算 = round(100 × compressed / (active + inactive + free + speculative + compressed))
显示警戒指数 = 原始估算 × 2
```

颜色独立读取系统压力状态。100% 只是约定的警戒参考值；系统滞回及其他因素会使实际变色点与它不同。它不是对未来内存压力的预测。

## 轻量与隐私

- 使用 Swift / AppKit 和系统统计接口；无第三方运行依赖、WebView 或常驻子进程。
- 单个定时器采样，数字或颜色变化时才重绘；默认每 5 秒刷新。
- 无联网、遥测、账号、广告或自动更新；不读取浏览器、个人文件或其他应用的内容。
- 只读取全机内存与 CPU 统计；只持久保存刷新频率。
- 本仓库不包含开发者的实际系统采样、个人路径、本机配置或验收日志。具体资源占用取决于系统环境。

详见 [PRIVACY.md](PRIVACY.md)。

## 从源码构建

需要 Apple Silicon Mac、macOS 13+ 和 Xcode Command Line Tools。

```sh
bash test.sh
bash build.sh
open "build/RAM Monitor.app"
```

构建输出为 `build/RAM Monitor.app`，无需第三方包。测试覆盖 RAM 指数、系统状态映射、CPU 增量计算、计数器回绕、阈值和睡眠恢复。

可选本地诊断：

```sh
"build/RAM Monitor.app/Contents/MacOS/RAMMonitor" --sample
"build/RAM Monitor.app/Contents/MacOS/RAMMonitor" --render-previews build/previews
```

`--sample` 输出本机实时统计，仅写入终端；分享前请自行检查。预览模式仅使用合成数据。

## License

[MIT](LICENSE)
