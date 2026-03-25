import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get firebaseUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  String get userName {
    if (_userModel != null) return _userModel!.name;
    if (firebaseUser?.displayName != null) return firebaseUser!.displayName!;
    return '';
  }

  String get userEmail {
    if (_userModel != null) return _userModel!.email;
    if (firebaseUser?.email != null) return firebaseUser!.email!;
    return '';
  }

  // Cargar datos del usuario desde Firestore
  Future<void> loadUserData() async {
    if (firebaseUser == null) return;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .get();
      if (doc.exists) {
        _userModel = UserModel.fromMap(doc.data()!);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Registro con email y contraseña
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name);

      // Crear documento en Firestore
      final userModel = UserModel(
        uid: credential.user!.uid,
        name: name,
        email: email,
      );
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userModel.toMap());

      _userModel = userModel;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Ocurrió un error. Intenta de nuevo.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login con email y contraseña
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await loadUserData();
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Ocurrió un error. Intenta de nuevo.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login con Google
  Future<bool> loginWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Verificar si el usuario ya existe en Firestore
      final doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!doc.exists) {
        // Nuevo usuario de Google - crear documento
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? 'Usuario',
          email: userCredential.user!.email ?? '',
        );
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userModel.toMap());
        _userModel = userModel;
      } else {
        _userModel = UserModel.fromMap(doc.data()!);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al iniciar con Google';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Verificar si un username ya existe
  Future<bool> isUsernameTaken(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // Actualizar perfil del usuario
  Future<bool> updateUserProfile({
    String? name,
    String? username,
    int? age,
    String? gender,
    List<String>? hobbies,
    List<String>? musicGenres,
    String? archetype,
  }) async {
    if (firebaseUser == null) return false;
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (username != null) updates['username'] = username.toLowerCase();
      if (age != null) updates['age'] = age;
      if (gender != null) updates['gender'] = gender;
      if (hobbies != null) updates['hobbies'] = hobbies;
      if (musicGenres != null) updates['musicGenres'] = musicGenres;
      if (archetype != null) updates['archetype'] = archetype;

      await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .update(updates);

      await loadUserData();
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _userModel = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado';
      case 'invalid-email':
        return 'Correo electrónico inválido';
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres)';
      case 'user-not-found':
        return 'No existe una cuenta con este correo';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-credential':
        return 'Credenciales inválidas. Verifica tu correo y contraseña';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento';
      default:
        return 'Ocurrió un error. Intenta de nuevo.';
    }
  }
}