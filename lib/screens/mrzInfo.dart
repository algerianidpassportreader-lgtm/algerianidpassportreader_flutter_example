import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:aaaa_project/constants.dart';
import 'package:aaaa_project/screens/mrz_screen.dart';

class MrzInfo extends StatelessWidget {
  const MrzInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Constants.str_primary_color,
        title: Text("MRZ", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                "assets/lotties/scan_mrz.json",
                height: 250,
                width: 250,
                fit: BoxFit.cover,
              ),
            ],
          ),
          const SizedBox(height: 40),

          Row(
            children: [
              Flexible(
                child: Text(
                  "Scan Document MRZ",
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                child: Text(
                  "You will need to scan the machine readable zone found At the bottom of the back side of the Document.",
                  style: TextStyle(color: Colors.black, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.str_primary_color,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              shadowColor: Constants.str_primary_color.withOpacity(0.3),
            ),
            child: Text("Scan MRZ", style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MRZScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
