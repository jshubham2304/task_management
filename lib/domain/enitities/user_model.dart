import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String? uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  const UserModel({
    this.uid,
    this.email,
    this.displayName,
    this.photoURL,
  });

  factory UserModel.fromFirebaseUser(dynamic firebaseUser) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
    );
  }

  @override
  List<Object?> get props => [uid, email, displayName, photoURL];
}
