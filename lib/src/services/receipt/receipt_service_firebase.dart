import 'dart:async';

import 'package:chat/chat.dart';
import 'package:chat/src/services/receipt/receipt_service_contract.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiptService implements IReceiptService {
  final FirebaseFirestore firestore;

  final _controller = StreamController<Receipt>.broadcast();
  StreamSubscription? _changefeed;
  late CollectionReference<Receipt> _receiptCollection;

  ReceiptService(this.firestore);

  @override
  init() async{
    _receiptCollection = firestore.collection('receipts').withConverter<Receipt>(
    fromFirestore: (snapshot, _) => Receipt.fromJson({
       'id':  snapshot.id,
       'recipient':  snapshot.data()!['recipient'],
       'message_id':  snapshot.data()!['messageId'],
       'status':  snapshot.data()!['status'],
       'timestamp':  snapshot.data()!['timestamp'].toDate()
    }),
    toFirestore: (receipt, _) => {
        'recipient': receipt.recipient,
        'messageId': receipt.messageId,
        'status': receipt.status.value(),
        'timestamp': receipt.timestamp
      });
  }

  @override
  dispose() {
    _changefeed?.cancel();
    _controller.close();
  }

  @override
  Stream<Receipt> receipts(User user) {
    _startReceivingReceipts(user);
    return _controller.stream;
  }

  @override
  Future<bool> send(Receipt receipt) async {
   await _receiptCollection.doc(receipt.id).set(receipt, SetOptions(
        merge: true
      ));
    return true;
  }

   _startReceivingReceipts(User user) {
    _changefeed = _receiptCollection
        .where('recipient', isEqualTo: user.id)
        .snapshots()
        .asBroadcastStream()
        .listen((snapData)async{
        if (snapData.docs.isEmpty) return;
      snapData.docs.forEach((feedData)  async{
        final receipt =  await _receiptFromFeed(feedData.id);
        if (receipt!=null) {
             _controller.sink.add(receipt);
            await _removeDeliverredReceipt(feedData.data());
        }
       });
    });
  }

  Future<Receipt?>  _receiptFromFeed(String id) async{
   final result =   await _receiptCollection.doc(id).get();
   return  result.data();
     
  }


  _removeDeliverredReceipt(Receipt receipt) async{
    _changefeed?.pause();
    await _receiptCollection.doc(receipt.id).delete();
    _changefeed?.resume();

  }

}
