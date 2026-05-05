# DYYY-Optimized

抖音越狱插件优化版本，基于 [DYYY](https://github.com/huami1314/DYYY) 进行改进。

## 优化内容

### 1. 修复已知问题
- **修复 IM 功能开关无效**：正确启用 `%group`，修复配置读取逻辑
- **修复编译错误**：修复语法错误，确保 CI/CD 构建通过
- **修复 nil 检查缺失**：在关键路径添加防御性 nil 检查

### 2. 代码结构优化
- **统一兼容层**：`DYYYCompat.h` 集中管理类名定义和安全查找
- **改进日志系统**：添加分级日志（DEBUG/ERROR/WARNING）
- **优化错误处理**：更完善的错误处理和用户提示

### 3. 功能改进
- **IM 滑动手势**：左滑引用消息，右滑撤回消息
- **阻止已读回执**：可选阻止消息已读状态上报
- **阻止访客记录**：可选阻止访客记录上传
- **视频下载优化**：更稳定的下载管理

## 构建

### 本地构建
```bash
# 标准版本
make package FINALPACKAGE=1

# Rootless 版本
make package SCHEME=rootless FINALPACKAGE=1

# RootHide 版本
make package SCHEME=roothide FINALPACKAGE=1
```

### CI/CD
项目已配置 GitHub Actions，推送代码后自动构建三种版本。

## 安装

1. 下载 `.deb` 文件
2. 通过 Filza 或 SSH 安装到设备
3. 重启抖音应用

## 配置

在抖音设置中点击 "DYYY" 按钮进入设置界面。

### IM 功能开关
- `DYYYEnableSwipeActions`：启用滑动手势（默认开启）
- `DYYYBlockReadReceipt`：阻止已读回执（默认关闭）
- `DYYYBlockVisitorUpload`：阻止访客记录（默认关闭）

## 开发原则

遵循 [COLLAB.md](COLLAB.md) 中的经验：

1. **先验证，再动手**：每个改动都有证据支撑
2. **最小改动**：只修必须修的，不动能跑的
3. **见好就收**：功能通了就停，不追求完美

## 致谢

- 原作者：[huami](https://github.com/huami1314)
- OpenClaw 和 TRAE CN 的协作经验

## License

MIT
