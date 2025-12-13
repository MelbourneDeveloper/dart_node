/// Parser for identifying executable lines in Dart source files.
library;

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:nadz/nadz.dart';

/// Parse a Dart file and return executable line numbers.
Result<List<int>, String> parseExecutableLines(
  String sourceCode,
  String filePath,
) {
  try {
    final parseResult = parseString(
      content: sourceCode,
      path: filePath,
      featureSet: FeatureSet.latestLanguageVersion(),
      throwIfDiagnostics: false,
    );

    final visitor = _ExecutableLineVisitor();
    parseResult.unit.visitChildren(visitor);

    final lines = visitor.executableLines.toList()..sort();
    return Success(lines);
  } on Exception catch (e) {
    return Error('Failed to parse $filePath: $e');
  }
}

/// Visitor that identifies executable lines in Dart AST.
/// ONLY instruments statements inside block bodies (not arrow functions).
class _ExecutableLineVisitor extends RecursiveAstVisitor<void> {
  final Set<int> executableLines = {};

  /// Check if node is inside a Block (curly braces), not an arrow function.
  bool _isInsideBlockBody(AstNode node) {
    // Walk up the tree to find the nearest function body
    var current = node.parent;
    while (current != null) {
      // If we hit a Block first, we're in a block body - good!
      if (current is Block) return true;
      // If we hit ExpressionFunctionBody (arrow function), skip this line
      if (current is ExpressionFunctionBody) return false;
      // If we hit a SwitchExpression, skip (can't add statements in there)
      if (current is SwitchExpression) return false;
      // If we reach a function/method declaration, stop looking
      if (current is FunctionDeclaration ||
          current is MethodDeclaration ||
          current is FunctionExpression) {
        return false;
      }
      current = current.parent;
    }
    return false;
  }

  void _addLine(AstNode node) {
    // Only add if inside a block body
    if (!_isInsideBlockBody(node)) return;

    final compilationUnit = node.thisOrAncestorOfType<CompilationUnit>();
    if (compilationUnit == null) return;
    final line = compilationUnit.lineInfo.getLocation(node.offset).lineNumber;
    executableLines.add(line);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    _addLine(node);
    super.visitExpressionStatement(node);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _addLine(node);
    super.visitVariableDeclarationStatement(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _addLine(node);
    super.visitReturnStatement(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    _addLine(node);
    super.visitIfStatement(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _addLine(node);
    super.visitSwitchStatement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    _addLine(node);
    super.visitForStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _addLine(node);
    super.visitWhileStatement(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _addLine(node);
    super.visitDoStatement(node);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    _addLine(node);
    super.visitAssertStatement(node);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    _addLine(node);
    super.visitBreakStatement(node);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    _addLine(node);
    super.visitContinueStatement(node);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _addLine(node);
    super.visitYieldStatement(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    _addLine(node);
    super.visitTryStatement(node);
  }
}
