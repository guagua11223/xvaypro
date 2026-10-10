import 'package:anyportal/screens/home/account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pending orders stay visible and block another purchase', () {
    final orders = <Map<String, dynamic>>[
      {'orderNo': 'new', 'payStatus': 1},
      {'orderNo': 'old', 'payStatus': 0},
    ];
    expect(orders.any(commerceOrderPending), isTrue);
    expect(visibleOrders(orders).first['orderNo'], 'old');
  });

  test('pay link prefers an http address', () {
    expect(
      payLink({'gateway': 'https://pay.example/cashier'}),
      'https://pay.example/cashier',
    );
    expect(
      payLink({'gateway': 'not-a-url', 'payUrl': 'https://pay.example/go'}),
      'https://pay.example/go',
    );
    expect(payLink({'gateway': ''}), isNull);
  });
}
