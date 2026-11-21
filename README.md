# Tsumiru fork

[官方 Suwayomi-Tsumiru](https://github.com/Suwayomi/Suwayomi-Tsumiru) 的 Windows 分支，
用于自行修 bug 与小幅改动，不跟进官方全量功能。

## 与官方版的差异

- 修复：关闭按钮延迟约 10 秒、中文系统下编译失败、启动窗口闪现
- 阅读器缩放（替代「阅读器内边距」）：50%–300%，Ctrl+滚轮随时调节，分页模式翻页后复位
- 底栏全屏按钮 + F12 全屏，全屏时隐藏标题栏

## 安装

[Releases](../../releases) 下载 zip 解压运行 `tsumiru.exe`，已捆绑 VC++ 运行时。
数据在 `%APPDATA%\com.suwayomi\Tsumiru`，与官方版互通。

## 构建

需要 Flutter 3.47.9（见 `.fvmrc`），先跑代码生成再构建：

```bash
dart run build_runner build --delete-conflicting-outputs
flutter build windows --release
```

## 许可

MPL-2.0，上游 © Suwayomi contributors。
