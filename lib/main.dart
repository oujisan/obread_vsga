import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/order_provider.dart';
import 'providers/product_provider.dart';
import 'views/landing_page.dart';
import 'package:device_preview/device_preview.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(
    DevicePreview(
      enabled: true, 
      builder: (context) => MyApp(),
      defaultDevice: Devices.android.samsungGalaxyS25,
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: 'Obread',
        theme: ThemeData(
          primarySwatch: Colors.brown,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: LandingPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
