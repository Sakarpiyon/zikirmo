import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/providers/providers.dart';

class SocialLinksScreen extends ConsumerStatefulWidget {
 const SocialLinksScreen({Key? key}) : super(key: key);

 @override
 ConsumerState<SocialLinksScreen> createState() => _SocialLinksScreenState();
}

class _SocialLinksScreenState extends ConsumerState<SocialLinksScreen> {
 final _formKey = GlobalKey<FormState>();
 
 late TextEditingController _instagramController;
 late TextEditingController _twitterController;
 late TextEditingController _facebookController;
 late TextEditingController _spotifyController;
 late TextEditingController _blueskyController;
 
 bool _isLoading = false;
 String? _errorMessage;
 
 @override
 void initState() {
   super.initState();
   _instagramController = TextEditingController();
   _twitterController = TextEditingController();
   _facebookController = TextEditingController();
   _spotifyController = TextEditingController();
   _blueskyController = TextEditingController();
   
   // Kullanıcı bilgilerini yükle
   _loadUserData();
 }
 
 @override
 void dispose() {
   _instagramController.dispose();
   _twitterController.dispose();
   _facebookController.dispose();
   _spotifyController.dispose();
   _blueskyController.dispose();
   super.dispose();
 }
 
 // Kullanıcı bilgilerini yükle
 Future<void> _loadUserData() async {
   final userAsync = ref.read(userProvider);
   
   userAsync.whenData((user) {
     if (user != null && user.socialLinks != null) {
       final socialLinks = user.socialLinks!;
       
       setState(() {
         _instagramController.text = socialLinks['instagram'] ?? '';
         _twitterController.text = socialLinks['twitter'] ?? '';
         _facebookController.text = socialLinks['facebook'] ?? '';
         _spotifyController.text = socialLinks['spotify'] ?? '';
         _blueskyController.text = socialLinks['bluesky'] ?? '';
       });
     }
   });
 }
 
 // Sosyal medya bağlantılarını güncelle
 Future<void> _updateSocialLinks() async {
   if (!_formKey.currentState!.validate()) return;
   
   setState(() {
     _isLoading = true;
     _errorMessage = null;
   });
   
   try {
     final authService = ref.read(authServiceProvider);
     final firestoreService = ref.read(firestoreServiceProvider);
     final userId = authService.currentUser?.uid;
     
     if (userId == null) {
       throw Exception('Kullanıcı bulunamadı');
     }
     
     // Sosyal medya bağlantılarını güncelle
     final socialLinks = <String, String>{};
     
     if (_instagramController.text.isNotEmpty) {
       socialLinks['instagram'] = _instagramController.text.trim();
     }
     
     if (_twitterController.text.isNotEmpty) {
       socialLinks['twitter'] = _twitterController.text.trim();
     }
     
     if (_facebookController.text.isNotEmpty) {
       socialLinks['facebook'] = _facebookController.text.trim();
     }
     
     if (_spotifyController.text.isNotEmpty) {
       socialLinks['spotify'] = _spotifyController.text.trim();
     }
     
     if (_blueskyController.text.isNotEmpty) {
       socialLinks['bluesky'] = _blueskyController.text.trim();
     }
     
     await firestoreService.updateUser(
       userId,
       {'socialLinks': socialLinks},
     );
     
     // Kullanıcı verilerini yenile
     ref.refresh(userProvider);
     
     if (mounted) {
       Navigator.pop(context);
       
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Sosyal medya bağlantıları güncellendi')),
       );
     }
   } catch (e) {
     setState(() {
       _errorMessage = 'Sosyal medya bağlantıları güncellenirken hata oluştu';
     });
   } finally {
     setState(() {
       _isLoading = false;
     });
   }
 }

 @override
 Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(
       title: Text('Sosyal Medya Bağlantıları'),
     ),
     body: SingleChildScrollView(
       child: Padding(
         padding: const EdgeInsets.all(16.0),
         child: Form(
           key: _formKey,
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 'Sosyal medya hesaplarını ekle veya güncelle',
                 style: Theme.of(context).textTheme.bodyLarge,
               ),
               const SizedBox(height: 24),
               
               // Instagram
               _buildSocialField(
                 _instagramController,
                 'Instagram',
                 Icons.camera_alt,
                 Colors.pink,
                 '@kullaniciadi',
               ),
               const SizedBox(height: 16),
               
               // Twitter
               _buildSocialField(
                 _twitterController,
                 'Twitter',
                 Icons.alternate_email,
                 Colors.blue,
                 '@kullaniciadi',
               ),
               const SizedBox(height: 16),
               
               // Facebook
               _buildSocialField(
                 _facebookController,
                 'Facebook',
                 Icons.facebook,
                 Colors.indigo,
                 'facebook.com/kullaniciadi',
               ),
               const SizedBox(height: 16),
               
               // Spotify
               _buildSocialField(
                 _spotifyController,
                 'Spotify',
                 Icons.music_note,
                 Colors.green,
                 'kullaniciadi',
               ),
               const SizedBox(height: 16),
               
               // Bluesky
               _buildSocialField(
                 _blueskyController,
                 'Bluesky',
                 Icons.cloud,
                 Colors.lightBlue,
                 '@kullaniciadi',
               ),
               const SizedBox(height: 24),
               
               // Hata mesajı
               if (_errorMessage != null) ...[
                 Text(
                   _errorMessage!,
                   style: const TextStyle(color: Colors.red),
                   textAlign: TextAlign.center,
                 ),
                 const SizedBox(height: 16),
               ],
               
               // Kaydet butonu
               SizedBox(
                 width: double.infinity,
                 height: 50,
                 child: _isLoading
                     ? const Center(child: CircularProgressIndicator())
                     : ElevatedButton(
                         onPressed: _updateSocialLinks,
                         child: Text('Kaydet'),
                       ),
               ),
             ],
           ),
         ),
       ),
     ),
   );
 }
 
 // Sosyal medya alan widget'ı
 Widget _buildSocialField(
   TextEditingController controller,
   String label,
   IconData icon,
   Color color,
   String hintText,
 ) {
   return TextFormField(
     controller: controller,
     decoration: InputDecoration(
       labelText: label,
       prefixIcon: Icon(icon, color: color),
       hintText: hintText,
       border: OutlineInputBorder(
         borderRadius: BorderRadius.circular(12),
       ),
     ),
   );
 }
}