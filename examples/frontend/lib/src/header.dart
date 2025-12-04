import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_react/dart_node_react.dart';
import 'package:frontend/src/types.dart';

/// Build app header component
HeaderElement buildHeader(JSObject? user, OnClick onLogout) => header(
  className: 'header',
  children: [
    div(
      className: 'header-content',
      children: [
        h1('TaskFlow', className: 'logo'),
        (user?['name']?.toString()).match(
          some: (userName) => div(
            className: 'user-info',
            children: [
              span('Welcome, $userName', className: 'user-name'),
              button(
                text: 'Logout',
                className: 'btn btn-ghost',
                onClick: onLogout,
              ),
            ],
          ),
          none: () => span('', className: 'spacer'),
        ),
      ],
    ),
  ],
);
