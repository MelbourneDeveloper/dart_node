import 'dart:io';
import 'package:node_preamble/preamble.dart' as preamble;

void main(List<String> args) {
  final input = args[0];
  final output = args[1];
  final addShebang = args.length > 2 && args[2] == '--shebang';
  final compiledJs = File(input).readAsStringSync();
  final shebang = addShebang ? '#!/usr/bin/env node\n' : '';
  final nodeJs = '$shebang${preamble.getPreamble()}\n$compiledJs';
  File(output).writeAsStringSync(nodeJs);
  print('Done: $output');
}
