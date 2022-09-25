import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/user/user_service_contract.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService implements IUserService {
  final FirebaseFirestore firestore;
  late CollectionReference<User> _userCollection;


  UserService(this.firestore);

  @override
  init() async{
    _userCollection = firestore.collection('users').withConverter<User>(
    fromFirestore: (snapshot, _) => User.fromJson({
       'id':  snapshot.id,
        'username': snapshot.data()!['username'],
        'photo_url': snapshot.data()!['photoUrl'],
        'active': snapshot.data()!['active'],
        'last_seen': snapshot.data()!['lastseen'].toDate(),
    }),
    toFirestore: (user, _) => {
        'username': user.username,
        'photoUrl': user.photoUrl,
        'active': user.active,
        'lastseen': user.lastseen,
      });
  }

  @override
  Future<User> connect(User user) async {
  var data = user.toJson();
  
    if(user.id == null){
      await _userCollection.add(user).then((value){
        data['id'] = value.id; 
      });
    }else{
      await _userCollection.doc(user.id).update(user.toJson());
    }
    return User.fromJson(data);
  }

  @override
  Future<void> disconnect(User user) async {
      await _userCollection.doc(user.id).update({
      'id': user.id,
      'active': false,
      'last_seen': DateTime.now(),
      });
  }

  @override
  Future<List<User>> online() async {
    final result =  await _userCollection.where('active', isEqualTo:  true).get(); 
    return result.docs.map((item) => item.data()).toList();
  }

  @override
  Future<User> fetch(String id) async {
    final result = await _userCollection.doc(id).get();
    return  result.data()!;
  }
}
