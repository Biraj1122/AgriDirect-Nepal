onPressed: () async {
  if (_formKey.currentState!.validate()) {
    String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    // Auto-append @gmail.com if no domain is provided
    if (!email.contains('@')) {
      email = "$email@gmail.com";
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 1. Authenticate user with Firebase Auth
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user == null) {
        if (context.mounted) Navigator.pop(context);
        return;
      }

      final String normalizedEmail = email.toLowerCase();

      // Admin emails supported from both branches
      final bool isAdminLogin =
          (normalizedEmail == "farmadmin@gmail.com" ||
                  normalizedEmail == "agrifarmadmin@gmail.com") &&
              password == "Farmadmin@1";

      // 2. Admin login bypasses email verification
      if (isAdminLogin) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': email,
          'role': 'Admin',
          'fullName': 'Super Admin',
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (context.mounted) {
          Navigator.pop(context); // Pop loading
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminPage()),
          );
        }
        return;
      }

      // 3. Email verification check for normal users
      if (!user.emailVerified) {
        await user.sendEmailVerification();

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final userData = userDoc.data() as Map<String, dynamic>?;

        if (context.mounted) {
          Navigator.pop(context); // Pop loading
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyOtpScreen(
                email: email,
                source: OtpSource.login,
                userData: userData,
              ),
            ),
          );
        }
        return;
      }

      // 4. Verified user role-based navigation
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() as Map<String, dynamic>?;

      if (context.mounted) {
        Navigator.pop(context); // Pop loading

        String role = userData?['role'] ?? 'Customer';

        Widget target;

        if (role == 'Farmer') {
          target = const FarmerScreen();
        } else if (role == 'Delivery Person') {
          target = const DeliveryPersonScreen();
        } else if (role == 'Admin') {
          target = const AdminPage();
        } else {
          target = NavigationScreen(
            userName: user.displayName ?? user.email ?? "User",
          );
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => target),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Login failed")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred: $e")),
        );
      }
    }
  }
},