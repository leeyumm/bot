# 3D 记忆卡牌战斗游戏

基于 Godot 4.x 开发的 3D 记忆卡牌对战游戏。

## 游戏玩法

- 桌面上铺有 16 张牌（8 对），背面朝上
- 玩家与 AI 轮流翻牌，每回合翻 2 张
- 配对成功：选择将点数加到「矛」（攻击）或「盾」（防御）
- 配对失败：牌翻回背面
- 小局结束（16 张牌全部配对）后结算战斗
- 伤害公式：`实际伤害 = max(1, 对方矛 - 我方盾)`
- HP 归零则游戏结束

## 如何运行

### 1. 安装 Godot 4.x

从 [godotengine.org](https://godotengine.org/download) 下载 Godot 4.x（推荐 4.3 或更高版本）

### 2. 打开项目

1. 启动 Godot 编辑器
2. 点击「导入」
3. 选择 `card_battle_game` 文件夹中的 `project.godot` 文件
4. 点击「导入并编辑」

### 3. 运行游戏

在 Godot 编辑器中按 **F5** 或点击右上角的「运行项目」按钮

## 项目结构

```
card_battle_game/
├── project.godot          # Godot 项目配置
├── icon.svg               # 项目图标
├── scenes/                # 场景文件
│   ├── main.tscn          # 主场景入口
│   ├── game/              # 游戏核心场景
│   │   ├── game_manager.tscn
│   │   └── table.tscn     # 3D 桌面
│   ├── cards/
│   │   └── card.tscn      # 卡牌场景
│   └── ui/                # UI 界面
│       ├── hud.tscn       # 血量/矛盾显示
│       └── allocation_popup.tscn  # 矛盾分配弹窗
├── scripts/               # GDScript 脚本
│   ├── autoloads/         # 全局单例
│   │   ├── game_state.gd  # 游戏状态
│   │   └── event_bus.gd   # 信号总线
│   ├── game/              # 游戏逻辑
│   │   ├── game_manager.gd
│   │   ├── turn_manager.gd
│   │   └── battle_resolver.gd
│   ├── cards/
│   │   ├── card.gd        # 卡牌行为
│   │   └── card_data.gd   # 卡牌数据
│   ├── ai/
│   │   └── ai_opponent.gd # AI 对手
│   ├── items/
│   │   └── item_manager.gd # 道具管理
│   └── ui/                # UI 脚本
│       ├── hud.gd
│       └── allocation_popup.gd
├── resources/             # 资源文件
│   └── cards/             # 卡牌数据资源
└── assets/                # 美术资源
    ├── textures/          # 贴图
    └── audio/             # 音效
```

## 核心系统

### 1. 卡牌系统
- 每张卡牌是一个 3D Node3D 节点
- 使用 Tween 实现翻牌动画（Y 轴旋转）
- 通过 Area3D 实现鼠标点击检测

### 2. 回合系统
- 状态机驱动（IDLE → PLAYER_TURN → CHECKING_MATCH → AI_TURN → BATTLE...）
- 通过 EventBus 信号总线解耦各模块

### 3. AI 系统
- 基于「记忆保留率」模型
- 简单难度：20-30% 记住翻过的牌
- 中等难度：50-60%，有基础策略
- 困难难度：80-90%，会根据血量调整攻防

### 4. 战斗系统
- 小局结束时结算
- 矛/盾数值在小局内累积
- 绝境加成：HP ≤ 30% 时配对点数 +1

### 5. 道具系统（已实现基础框架）
- 窥视：偷看 1 张牌
- 洗牌：打乱未配对的牌
- 双倍：下次配对点数 ×2
- 镜像：复制对手上回合分配

## 开发进度

- [x] Phase 0：项目结构和配置
- [x] Phase 1：3D 卡牌场景和翻牌交互
- [x] Phase 2：记忆配对逻辑和回合系统
- [x] Phase 3：AI 对手
- [x] Phase 4：战斗系统（矛/盾分配 + 结算）
- [x] Phase 5：道具系统（基础框架）
- [ ] Phase 6：主菜单、音效、打磨

## 后续优化方向

1. **视觉优化**
   - 更精美的卡牌贴图
   - 粒子特效（配对成功、战斗结算）
   - 卡牌高亮选中效果

2. **音效**
   - 翻牌音效
   - 配对成功/失败音效
   - 战斗结算音效
   - 背景音乐

3. **UI 完善**
   - 主菜单（开始游戏、选择难度）
   - 游戏结束画面（胜利/失败）
   - 道具 UI（道具栏 + 使用按钮）

4. **玩法扩展**
   - 多轮对局（Bo3 / Bo5）
   - 更多道具类型
   - 特殊卡牌（陷阱牌、万能牌）

## 技术要点

- **Godot 4.x** 的 GDScript 语法
- **Autoload** 单例模式（GameState、EventBus）
- **信号（Signal）** 解耦系统
- **Tween** 动画系统
- **正交相机** 避免透视畸变
- **状态机** 驱动游戏流程

## 许可

本项目仅供学习交流使用。
