# dart_node_coverage

用于使用 dart2js 编译并在 Node.js 中执行的 Dart 代码的代码覆盖率收集工具。

## 架构

此包提供 Dart 源代码的编译时插桩功能，以便在通过 dart2js 在 Node.js 中运行测试时启用行覆盖率跟踪。

详细架构文档请参阅 [lib/src/architecture.dart](lib/src/architecture.dart)。

## 主要功能

- **编译时插桩**：在 dart2js 编译前插入覆盖率探针
- **LCOV 输出**：与 genhtml、coveralls 等兼容的标准格式
- **与 dart test 集成**：与现有测试工作流程配合使用
- **禁用时零运行时开销**：无插桩则无成本

## 工作原理

1. **分析** Dart 源代码以识别可执行行
2. **插桩** 源代码，插入覆盖率探针调用
3. **编译** 使用 dart2js 编译插桩后的源代码
4. **执行** 在 Node.js 中运行测试（自动收集覆盖率）
5. **生成** 从覆盖率数据生成 LCOV 报告

## 状态

此包处于早期开发阶段。架构已定义，实现正在进行中。
