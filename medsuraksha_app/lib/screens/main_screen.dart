import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'scan_screen.dart';

class MainScreen extends StatefulWidget {
  final String? userName;

  const MainScreen({super.key, this.userName});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      HomeScreen(userName: widget.userName),
      const Center(child: Text("History", style: TextStyle(color: Colors.white))),
      const Center(child: Text("AI Assistant", style: TextStyle(color: Colors.white))),
      const Center(child: Text("Profile", style: TextStyle(color: Colors.white))),
    ];
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: pages[currentIndex],

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.qr_code_scanner,color: Colors.black),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScanScreen()),
          );
        },
      ),

      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: const Color(0xff161B22),

        shape: const CircularNotchedRectangle(),

        child: SizedBox(
          height: 70,

          child: Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceAround,

            children: [

              IconButton(
                icon: const Icon(Icons.home),
                color: currentIndex==0
                    ? Colors.greenAccent
                    : Colors.white54,
                onPressed: (){
                  setState(() {
                    currentIndex=0;
                  });
                },
              ),

              IconButton(
                icon: const Icon(Icons.history),
                color: currentIndex==1
                    ? Colors.greenAccent
                    : Colors.white54,
                onPressed: (){
                  setState(() {
                    currentIndex=1;
                  });
                },
              ),

              const SizedBox(width:40),

              IconButton(
                icon: const Icon(Icons.smart_toy),
                color: currentIndex==2
                    ? Colors.greenAccent
                    : Colors.white54,
                onPressed: (){
                  setState(() {
                    currentIndex=2;
                  });
                },
              ),

              IconButton(
                icon: const Icon(Icons.person),
                color: currentIndex==3
                    ? Colors.greenAccent
                    : Colors.white54,
                onPressed: (){
                  setState(() {
                    currentIndex=3;
                  });
                },
              ),

            ],
          ),
        ),
      ),
    );
  }
}