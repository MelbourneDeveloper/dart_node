import 'dart:io';
import 'package:node_preamble/preamble.dart' as preamble;

void main(List<String> args) {
  final input = args[0];
  final output = args[1];
  final compiledJs = File(input).readAsStringSync();
  final nodeJs = '${preamble.getPreamble()}\n$compiledJs';
  File(output).writeAsStringSync(nodeJs);
  print('Done: $output');
}
