// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'firebase_options.dart';

class FirebaseWrapper {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static late String username;
  static late String aboutText;
  static Image profilePicture = Image.asset('user.png');
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await syncUsername();
    await syncProfilePic();
    await syncAboutText();
  }

  static Future<void> syncAboutText() async {
    aboutText = "";
    if (auth.currentUser != null) {
      final CollectionReference usersCollection =
          FirebaseFirestore.instance.collection('users');
      final DocumentReference userDocument =
          usersCollection.doc(auth.currentUser!.uid);
      final DocumentSnapshot snapshot = await userDocument.get();
      if (snapshot.exists) {
        final userData = snapshot.data() as Map<String, dynamic>;
        aboutText = userData['about'] ?? "";
      } else {
        print('User document does not exist');
      }
    }
  }

  static Future<void> saveAboutText(String aboutText) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(auth.currentUser!.uid)
        .update({'about': aboutText});
  }

  static Future<void> syncProfilePic() async {
    if (auth.currentUser != null) {
      try {
        String filePath = 'profile_images/${auth.currentUser!.uid}.jpg';
        Reference storageReference =
            FirebaseStorage.instance.ref().child(filePath);
        String downloadURL = await storageReference.getDownloadURL();
        profilePicture = Image.network(downloadURL);
      } catch (e) {
        print(e);
      }
    }
  }

  static Future<void> syncUsername() async {
    if (auth.currentUser != null) {
      final CollectionReference usersCollection =
          FirebaseFirestore.instance.collection('users');
      final DocumentReference userDocument =
          usersCollection.doc(auth.currentUser!.uid);
      final DocumentSnapshot snapshot = await userDocument.get();
      if (snapshot.exists) {
        final userData = snapshot.data() as Map<String, dynamic>;
        username = userData['username'];
      } else {
        print('User document does not exist');
      }
    }
  }

  static Future<void> updateUsername(String username) async {
    final CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('users');
    final DocumentReference userDocument =
        usersCollection.doc(FirebaseWrapper.auth.currentUser!.uid);

    await userDocument.update({
      'username': username,
    });
  }

  static Future<Image?> uploadPic() async {
    late Image finalImage;
    final FirebaseStorage storage = FirebaseStorage.instance;
    final Reference storageReference =
        storage.ref().child('profile_images/${auth.currentUser!.uid}.jpg');
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      try {
        storageReference.putData(await streamToUint8List(image.openRead()));
        finalImage = Image.network(image.path);
      } catch (e) {
        print(e);
      }
    }
    return finalImage;
  }

  static Future<Uint8List> streamToUint8List(Stream<Uint8List> stream) async {
    final bytesBuilder = BytesBuilder();
    await for (var data in stream) {
      bytesBuilder.add(data);
    }
    return bytesBuilder.toBytes();
  }

  static Future<String> signUpWithUsername(
      String email, String password, String username) async {
    try {
      // Add the username to Firestore
      bool uniqueUsername = await usernameUnique(username);
      if (uniqueUsername) {
        // Create the user in Firebase Authentication with email and password
        UserCredential userCredential =
            await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        // Set remember me to true
        await auth.setPersistence(Persistence.LOCAL);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({'username': username});
        return 'signed-up';
      } else {
        return 'username-already-in-use';
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
      return e.code;
    } catch (e) {
      print(e);
      return 'Error';
    }
  }

  static Future<bool> usernameUnique(String username) async {
    bool uniqueUsername = false;
    await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        // Username is unique, insert it into Firestore
        uniqueUsername = true;
      } else {}
    });
    return uniqueUsername;
  }

  static Future<void> signOut() async {
    await auth.signOut();
  }

  static Future<String> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      // Set remember me to true
      await auth.setPersistence(Persistence.LOCAL);
      // User is signed in
      return 'signed-in';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
      return e.code;
    }
  }
}
