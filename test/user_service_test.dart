import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/user/user_service_firebase.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  late FakeFirebaseFirestore firestore;
  late UserService sut;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    sut = UserService(firestore);
    sut.init();
  });

  tearDown(() async {

  });

  test('creates a new user document in database', () async {
    final user = User(
      username: 'test',
      photoUrl: 'url',
      active: true,
      lastseen: DateTime.now(),
    );
    final userWithId = await sut.connect(user);
    expect(userWithId.id, isNotEmpty);
  });

  test('get online users', () async {
    final user = User(
      username: 'test',
      photoUrl: 'url',
      active: true,
      lastseen: DateTime.now(),
    );
    //arrange
    await sut.connect(user);
    //act
    final users = await sut.online();
    //assert
    expect(users.length, 1);
  });
}
