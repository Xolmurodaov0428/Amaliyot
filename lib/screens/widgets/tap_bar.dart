import 'package:student_amaliyot_app/screens/widgets/faoliyat/faoliyat_screen.dart';
import 'package:student_amaliyot_app/widgets/davomat_page.dart';
import 'package:student_amaliyot_app/widgets/dashboard_page.dart';
import 'package:student_amaliyot_app/widgets/topshiriq_page.dart';
import '../../constants/app_colors.dart';
import '../../utils/tools/file_importers.dart';
import '../sozlamalar_screen.dart';

class TapBarPage extends StatelessWidget {
  const TapBarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Status barni shaffof qiladi
        statusBarIconBrightness: Brightness.light, // Android uchun qora ikonlar
        statusBarBrightness: Brightness.light, // iOS uchun
      ),
      child: SafeArea(
        child: DefaultTabController(
          length: 5,
          child: Scaffold(
            body: TabBarView(
              physics: const BouncingScrollPhysics(),
              children: [
                StudentPortalPage(), // <-- SHU YERDA SCROLL YO'Q BO'LSIN!

                // Center(child: Text("📋 Topshiriqlar", style: TextStyle(fontSize: 20))),

                TopshiriqlarPage(),

                DavomatPage(), // bunda scroll bo'lsa o'zida bo'lsin

                // Center(child: Text("📸 Hujjatlar", style: TextStyle(fontSize: 20))),
                FaoliyatPage(),

                // Center(child: Text("⚙️ Sozlamalar", style: TextStyle(fontSize: 20))),
                SettingPage()
              ],
            ),

            bottomNavigationBar: Container(
              height: 90,
              decoration: const BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.accentPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.amber,
                indicatorWeight: 3,
                tabs: [
                  Tab(icon: Icon(Icons.home), text: "Bosh sahifa"),
                  Tab(icon: Icon(Icons.assignment), text: "Topshiriqlar"),
                  Tab(icon: Icon(Icons.calendar_today), text: "Davomat"),
                  Tab(icon: Icon(Icons.create_new_folder_outlined), text: "Hujjatlar"),
                  Tab(icon: Icon(Icons.settings), text: "Sozlamalar"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
