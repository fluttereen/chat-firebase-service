import 'package:chat/chat.dart';
import 'package:chat/src/services/typing/typing_notification.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  late FakeFirebaseFirestore firestore;
  late TypingNotification sut;
  late IUserService userService;
  late User user; 
  late User user2; 



  


  setUp(() async {
    firestore = FakeFirebaseFirestore();
    userService = UserService(firestore);
    sut = TypingNotification(firestore, userService);
    sut.init();
    userService.init();
    user =  await userService.connect(User.fromJson({
     'username' : 'kashif',
    'photo_url' : '#',
    'active': true,
    'last_seen': DateTime.now(),
  }));
  user2 =  await userService.connect(User.fromJson({
    'username' : 'rahul',
    'photo_url' : '#',
    'active': true,
    'last_seen': DateTime.now(),
  }));
  });

  tearDown(() async {
    //sut.dispose();
  });

  test('sent typing notification successfully', () async {
    TypingEvent typingEvent =
        TypingEvent(from: user2.id!, to: user.id!, event: Typing.start);
   
   final res = await sut.send(typingEvent);
   expect(res, true);
  });

  test('successfully subscribe and receive typing events', () async {
    sut.subscribe(user2, [user.id!]).listen(expectAsync1((event) async{
      expect(event.from, user.id);
    }, count: 2));

    TypingEvent typing = TypingEvent(
      to: user2.id!,
      from: user.id!,
      event: Typing.start,
    );

    TypingEvent stopTyping = TypingEvent(
      to: user2.id!,
      from: user.id!,
      event: Typing.stop,
    );

    await sut.send(typing);
    await sut.send(stopTyping);
  });
}
