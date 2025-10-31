import 'package:flutter/material.dart';

class AppBarPage extends StatelessWidget {
  final String title;

  const AppBarPage({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🔹 O‘ng tomondagi tugmalar til ikonasi
          Positioned(
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.language, color: Colors.white, size: 30),
              onPressed: () {},
            ),
          ),

          // 🔹 O‘rtadagi sarlavha
          Center(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),

          // 🔹 Chap tomondagi profil
          Positioned(
            left: 8,
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const CircleAvatar(
                radius: 22,
                // backgroundImage: AssetImage("assets/images/profile.jpg"),
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// import 'package:flutter/material.dart';

// class AppBarPage extends StatelessWidget {
//   final String title;
//   final VoidCallback? onProfileTap;
//   final VoidCallback? onLanguageTap;
//   final String? profileImagePath;
//
//   const AppBarPage({
//     required this.title,
//     this.onProfileTap,
//     this.onLanguageTap,
//     this.profileImagePath,
//     super.key,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 90,
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Colors.blue, Colors.purple],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: const BorderRadius.only(
//           bottomLeft: Radius.circular(20),
//           bottomRight: Radius.circular(20),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.deepPurple.withOpacity(0.4),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 8),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               // Profile Avatar (Left)
//               GestureDetector(
//                 onTap: onProfileTap,
//                 child: Container(
//                   padding: const EdgeInsets.all(2),
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.white, width: 2),
//                   ),
//                   child: CircleAvatar(
//                     radius: 22,
//                     backgroundColor: Colors.white,
//                     backgroundImage: profileImagePath != null
//                         ? AssetImage(profileImagePath!)
//                         : null,
//                     child: profileImagePath == null
//                         ? const Icon(
//                       Icons.person,
//                       color: Colors.blue,
//                       size: 28,
//                     )
//                         : null,
//                   ),
//                 ),
//               ),
//
//               // Title (Center)
//               Expanded(
//                 child: Center(
//                   child: Text(
//                     title,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 22,
//                       fontWeight: FontWeight.w600,
//                       letterSpacing: 1,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ),
//
//               // Language Button (Right)
//               IconButton(
//                 icon: const Icon(
//                   Icons.language,
//                   color: Colors.white,
//                   size: 30,
//                 ),
//                 onPressed: onLanguageTap ?? () {},
//                 tooltip: 'Change Language',
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // Example usage:
// class ExampleUsage extends StatelessWidget {
//   const ExampleUsage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           AppBarPage(
//             title: "Dashboard",
//             onProfileTap: () {
//               // Navigate to profile
//               print("Profile tapped");
//             },
//             onLanguageTap: () {
//               // Show language selector
//               print("Language tapped");
//             },
//             // profileImagePath: "assets/images/profile.jpg",
//           ),
//           const Expanded(
//             child: Center(
//               child: Text("Your content here"),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }