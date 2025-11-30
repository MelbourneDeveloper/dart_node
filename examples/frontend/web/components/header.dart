import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:dart_node_react/dart_node_react.dart';
import 'package:shared/theme/theme.dart';
import '../types.dart';

/// Build app header component
JSObject buildHeader(JSObject? user, OnClick onLogout) {
  final userName = user?.getProperty('name'.toJS)?.toString();
  return header(
    style: AppStyles.header,
    children: [
      div(
        style: AppStyles.headerContent,
        children: [
          h1('TaskFlow', style: AppStyles.logo),
          if (userName != null)
            div(
              style: AppStyles.userInfo,
              children: [
                span('Welcome, $userName', style: AppStyles.headerUserName),
                button(
                  text: 'Logout',
                  style: AppStyles.btnGhost,
                  onClick: onLogout,
                ),
              ],
            )
          else
            span('', style: AppStyles.spacer),
        ],
      ),
    ],
  );
}
