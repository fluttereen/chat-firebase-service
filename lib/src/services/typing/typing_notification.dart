import 'dart:async';
import 'dart:developer';
import 'package:chat/chat.dart';
import 'package:chat/src/services/typing/typing_notification_service_contract.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TypingNotification implements ITypingNotification {
  
  final FirebaseFirestore firestore;
  final _controller = StreamController<TypingEvent>.broadcast();
  StreamSubscription? _changefeed;
  IUserService userService;

  late CollectionReference<TypingEvent> _typingCollection;

  TypingNotification(this.firestore, this.userService);
 
  @override
  init() async{
    _typingCollection = firestore.collection('typing_events').withConverter<TypingEvent>(
    fromFirestore: (snapshot, _) => TypingEvent.fromJson({
       'id':  snapshot.id,
       'from':  snapshot.data()!['from'],
       'to':  snapshot.data()!['to'],
       'event':  snapshot.data()!['event'],
    }),
    toFirestore: (typingEvent, _) => {
        'from': typingEvent.from,
        'to': typingEvent.to,
        'event': typingEvent.event.value()
      });
  }

  @override
  Future<bool> send(TypingEvent event) async {
    final receiver = await userService.fetch(event.to);
    if (!receiver.active) return false;

    await _typingCollection.doc(event.id).set(event, SetOptions(
        merge: true
      ));
    return true;
  }

  @override
  Stream<TypingEvent> subscribe(User user, List<String> userIds) {
    _startReceivingTypingEvents(user, userIds);
    return _controller.stream;
  }

  @override
  void dispose() {
    _changefeed?.cancel();
    _controller.close();
  }

  _startReceivingTypingEvents(User user, List<String> userIds) {
    
    _changefeed = _typingCollection
        .where('to', isEqualTo: user.id)
        .where('from', whereIn: userIds)
        .snapshots()
        .asBroadcastStream()
        .listen((snapData)async{
        if (snapData.docs.isEmpty) return;
      snapData.docs.forEach((feedData)  async{
        final event =  await _eventFromFeed(feedData.id);
        if (event!=null) {
             _controller.sink.add(event);
            await _removeEvent(feedData.data());
        }
       });
    });
  }

  Future<TypingEvent?> _eventFromFeed(id) async{
   final result =   await _typingCollection.doc(id).get();
   return  result.data();
     
  }

  _removeEvent(TypingEvent event)async {
      _changefeed?.pause();
    await _typingCollection.doc(event.id).delete();
    _changefeed?.resume();
  }
}
