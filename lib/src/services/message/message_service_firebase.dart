import 'dart:async';
import 'dart:developer';

import 'package:chat/src/models/message.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/encryption/encryption_contract.dart';
import 'package:chat/src/services/message/message_service_contract.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageService implements IMessageService {
  final FirebaseFirestore firestore;
  final IEncryption encryption;

  final _controller = StreamController<Message>.broadcast();
  StreamSubscription? _changefeed;
  late CollectionReference<Message> _messageCollection;

  MessageService(this.firestore, this.encryption);


  @override
  init() async{
    _messageCollection = firestore.collection('messages').withConverter<Message>(
    fromFirestore: (snapshot, _) => Message.fromJson({
       'id':  snapshot.id,
       'from':  snapshot.data()!['from'],
       'to':  snapshot.data()!['to'],
       'contents':  encryption.decrypt(snapshot.data()!['contents']),
       'timestamp':  snapshot.data()!['timestamp'].toDate()
    }),
    toFirestore: (message, _) => {
        'from': message.from,
        'to': message.to,
        'timestamp': message.timestamp,
        'contents': encryption.encrypt(message.contents)
      });
  }

  @override
  dispose() {
    _changefeed?.cancel();
    _controller.close();
  }

  @override
  Stream<Message> messages(User activeUser) {
    _startReceivingMessages(activeUser);
    return _controller.stream;
  }

  @override
  Future<Message> send(Message message) async {
   await _messageCollection.doc(message.id).set(message, SetOptions(
        merge: true
      ));
    return message;
  }

   _startReceivingMessages(User activeUser) {
    _changefeed = _messageCollection
        .where('to', isEqualTo: activeUser.id)
        .snapshots()
        .asBroadcastStream()
        .listen((snapData)async{
        if (snapData.docs.isEmpty) return;
      snapData.docs.forEach((feedData)  async{
        final message =  await _messageFromFeed(feedData.id);
        if (message!=null) {
             _controller.sink.add(message);
            await _removeDeliverredMessage(feedData.data());
        }
       });
    });
  }

  Future<Message?>  _messageFromFeed(String id) async{
   final result =   await _messageCollection.doc(id).get();

   return  result.data();
     
  }


  _removeDeliverredMessage(Message message) async{
    _changefeed?.pause();
    await _messageCollection.doc(message.id).delete();
    _changefeed?.resume();

  }

}
