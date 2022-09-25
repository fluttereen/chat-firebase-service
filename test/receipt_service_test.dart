import 'package:chat/src/models/receipt.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/receipt/receipt_service_firebase.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {

  late FakeFirebaseFirestore firestore;
  late ReceiptService sut;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    sut = ReceiptService(firestore);
    sut.init();
  });

  tearDown(() async {
    //sut.dispose();
  });

  final user = User.fromJson({
     'id': '1234',
    'username' : 'kashif',
    'photo_url' : '#',
    'active': true,
    'last_seen': DateTime.now(),
  });

  test('sent receipt successfully', () async {
    Receipt receipt = Receipt(
        recipient: '444',
        messageId: '1234',
        status: ReceiptStatus.deliverred,
        timestamp: DateTime.now());

    final res = await sut.send(receipt);
    expect(res, true);
  });

  test('successfully subscribe and receive receipts', () async {
    sut.receipts(user).listen(expectAsync1((receipt) {
          expect(receipt.recipient, user.id);
        }, count: 2));

    Receipt receipt = Receipt(
        recipient: user.id!,
        messageId: '1234',
        status: ReceiptStatus.deliverred,
        timestamp: DateTime.now(),);

    Receipt anotherReceipt = Receipt(
        recipient: user.id!,
        messageId: '1234',
        status: ReceiptStatus.read,
        timestamp: DateTime.now(),);

    await sut.send(receipt);
    await sut.send(anotherReceipt);
  });
}
