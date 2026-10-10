import 'package:anyportal/screens/home/login.dart';
import 'package:anyportal/screens/home/register.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login page shows account fields', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 844));
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.text('登录'), findsWidgets);
    expect(find.text('用户名或邮箱'), findsOneWidget);
    expect(find.text('密码'), findsOneWidget);
    expect(find.text('没有账号，去注册'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('register page includes invite code', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 844));
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    expect(find.text('注册'), findsWidgets);
    expect(find.text('用户名或邮箱'), findsOneWidget);
    expect(find.text('密码'), findsOneWidget);
    expect(find.text('邀请码，选填'), findsOneWidget);
    expect(find.text('已有账号，去登录'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
