/// Tests for agent plan operations.
library;

import 'dart:js_interop';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';
import 'package:too_many_cooks_data/too_many_cooks_data.dart';

extension type _Fs(JSObject _) implements JSObject {
  external void unlinkSync(String path);
  external bool existsSync(String path);
}

final _Fs _fs = _Fs(requireModule('fs') as JSObject);

void _deleteIfExists(String path) {
  try {
    if (_fs.existsSync(path)) {
      _fs.unlinkSync(path);
    }
  } on Object catch (_) {}
}

void main() {
  const testDbPath = '.test_plans.db';
  TooManyCooksDb? db;
  var agentName = '';
  var agentKey = '';

  setUp(() {
    _deleteIfExists(testDbPath);
    final config = createDataConfig(dbPath: testDbPath);
    final result = createDb(config);
    expect(result, isA<Success<TooManyCooksDb, String>>());
    db = (result as Success<TooManyCooksDb, String>).value;

    // Register test agent
    final regResult = db!.register('plan-agent');
    final reg = (regResult as Success<AgentRegistration, DbError>).value;
    agentName = reg.agentName;
    agentKey = reg.agentKey;
  });

  tearDown(() {
    db?.close();
    _deleteIfExists(testDbPath);
  });

  test('updatePlan creates new plan', () {
    final result = db!.updatePlan(
      agentName,
      agentKey,
      'Fix all bugs',
      'Reading codebase',
    );
    expect(result, isA<Success<void, DbError>>());
  });

  test('updatePlan updates existing plan', () {
    db!.updatePlan(agentName, agentKey, 'Goal 1', 'Task 1');

    final result = db!.updatePlan(agentName, agentKey, 'Goal 2', 'Task 2');
    expect(result, isA<Success<void, DbError>>());

    final getPlan = db!.getPlan(agentName);
    final plan = (getPlan as Success<AgentPlan?, DbError>).value!;
    expect(plan.goal, 'Goal 2');
    expect(plan.currentTask, 'Task 2');
  });

  test('updatePlan fails with invalid credentials', () {
    final result = db!.updatePlan(agentName, 'wrong-key', 'Goal', 'Task');
    expect(result, isA<Error<void, DbError>>());
    final error = (result as Error<void, DbError>).error;
    expect(error.code, errUnauthorized);
  });

  test('updatePlan fails for goal exceeding max length', () {
    final longGoal = 'x' * 101; // Default max is 100
    final result = db!.updatePlan(agentName, agentKey, longGoal, 'Task');
    expect(result, isA<Error<void, DbError>>());
    final error = (result as Error<void, DbError>).error;
    expect(error.code, errValidation);
    expect(error.message, contains('100'));
  });

  test('updatePlan fails for task exceeding max length', () {
    final longTask = 'x' * 101;
    final result = db!.updatePlan(agentName, agentKey, 'Goal', longTask);
    expect(result, isA<Error<void, DbError>>());
    final error = (result as Error<void, DbError>).error;
    expect(error.code, errValidation);
  });

  test('getPlan returns plan for agent', () {
    db!.updatePlan(agentName, agentKey, 'My Goal', 'Current Task');

    final result = db!.getPlan(agentName);
    expect(result, isA<Success<AgentPlan?, DbError>>());
    final plan = (result as Success<AgentPlan?, DbError>).value;
    expect(plan, isNotNull);
    expect(plan!.agentName, agentName);
    expect(plan.goal, 'My Goal');
    expect(plan.currentTask, 'Current Task');
    expect(plan.updatedAt, greaterThan(0));
  });

  test('getPlan returns null for agent without plan', () {
    // Register agent without setting plan
    final reg2 = db!.register('no-plan-agent');
    final agent2 = (reg2 as Success<AgentRegistration, DbError>).value;

    final result = db!.getPlan(agent2.agentName);
    expect(result, isA<Success<AgentPlan?, DbError>>());
    final plan = (result as Success<AgentPlan?, DbError>).value;
    expect(plan, isNull);
  });

  test('listPlans returns all plans', () {
    db!.updatePlan(agentName, agentKey, 'Goal 1', 'Task 1');

    // Register second agent with plan
    final reg2 = db!.register('plan-agent-2');
    final agent2 = (reg2 as Success<AgentRegistration, DbError>).value;
    db!.updatePlan(agent2.agentName, agent2.agentKey, 'Goal 2', 'Task 2');

    final result = db!.listPlans();
    expect(result, isA<Success<List<AgentPlan>, DbError>>());
    final plans = (result as Success<List<AgentPlan>, DbError>).value;
    expect(plans.length, 2);
    expect(plans.map((p) => p.goal).toSet(), {'Goal 1', 'Goal 2'});
  });

  test('plan updatedAt changes on update', () {
    db!.updatePlan(agentName, agentKey, 'Goal', 'Task 1');
    final getPlan1 = db!.getPlan(agentName);
    final plan1 = (getPlan1 as Success<AgentPlan?, DbError>).value;

    db!.updatePlan(agentName, agentKey, 'Goal', 'Task 2');
    final getPlan2 = db!.getPlan(agentName);
    final plan2 = (getPlan2 as Success<AgentPlan?, DbError>).value;

    expect(plan2!.updatedAt, greaterThanOrEqualTo(plan1!.updatedAt));
  });
}
