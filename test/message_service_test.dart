import 'dart:developer';

import 'package:chat/src/models/message.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/encryption/encryption_service.dart';
import 'package:chat/src/services/message/message_service_firebase.dart';
import 'package:encrypt/encrypt.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  late FakeFirebaseFirestore firestore;
  late MessageService sut;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    final encryption = EncryptionService(Encrypter(AES(Key.fromLength(32))));
    sut = MessageService(firestore, encryption);
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

  final user2 = User.fromJson({
    'id': '1111',
    'username' : 'rahul',
    'photo_url' : '#',
    'active': true,
    'last_seen': DateTime.now(),
  });

  test('sent message successfully', () async {
    Message message = Message(
      from: user.id!,
      to: '3456',
      timestamp: DateTime.now(),
      contents: 'this is a message',
    );

    final res = await sut.send(message);
    expect(res, isNotEmpty);
  });

  test('successfully subscribe and receive messages', () async {
   
    sut.messages(user2).listen(expectAsync1((message) {
         log("Message ::  ${message.toJson()}");
          expect(message.to, user2.id);
          expect(message.id, isNotEmpty);
          expect(message.contents, isNotEmpty);
        }, count: 2));

    Message message = Message(
      from: user.id!,
      to: user2.id!,
      timestamp: DateTime.now(),
      contents: "this is a message",
    );

    Message secondMessage = Message(
      from: user.id!,
      to: user2.id!,
      timestamp: DateTime.now(),
      contents: "this is another message",
    );

    await sut.send(message);
    await sut.send(secondMessage);
  });

  test('successfully subscribe and receive new messages ', () async {
    Message message = Message(
      from: user.id!,
      to: user2.id!,
      timestamp: DateTime.now(),
      contents: 'this is a message',
    );

    Message secondMessage = Message(
      from: user.id!,
      to: user2.id!,
      timestamp: DateTime.now(),
      contents: 'this is another message',
    );

    await sut.send(message);
    await sut.send(secondMessage).whenComplete(
          () => sut.messages(user2).listen(
                expectAsync1((message) {
                  log("Message ::  ${message.toJson()}");
                  expect(message.to, user2.id);
                }, count: 2),
              ),
        );
  });
}
