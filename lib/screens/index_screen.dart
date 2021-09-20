// import 'package:circulr_app/screens/login_screen.dart';
// import 'package:circulr_app/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'map_screen.dart';
import 'returns_page.dart';

class IndexScreen extends StatefulWidget {
  const IndexScreen({Key? key}) : super(key: key);

  @override
  _IndexScreenState createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  int _currentIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const List<Widget> _widgetOptions = <Widget>[
    // Text(
    //   'Index 0: Home',
    //   style: optionStyle,
    // ),
    HomeScreen(),
    MapScreen(),
    // Text(
    //   'Index 1: Collection Centres',
    //   style: optionStyle,
    // ),
    ReturnsPage(),
    // Text(
    //   'Index 2: Returns',
    //   style: optionStyle,
    // ),
    ProfileScreen(),
    // Text(
    //   'Index 3: Profile',
    //   style: optionStyle,
    // )
    // IndexScreen(),
    // RegisterScreen(),
    // LoginScreen(),
    // RegisterScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Circulr Home'),
      //   backgroundColor: Colors.green,
      // ),
      body: Center(
        child: _widgetOptions.elementAt(_currentIndex),
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Header'),
            ),
            ListTile(
                title: const Text('How it Works'),
                onTap: () {
                  Navigator.pop(context);
                }),
            ListTile(
                title: const Text('Our Brands'),
                onTap: () {
                  Navigator.pop(context);
                }),
            ListTile(
                title: const Text('Referals'),
                onTap: () {
                  Navigator.pop(context);
                }),
            ListTile(
                title: const Text('FAQ'),
                onTap: () {
                  Navigator.pop(context);
                }),
            ElevatedButton(
                child: Text('Sign Out'),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                }),
          ],
        ),
      ),
      // body: (Column(
      //   children: [
      //     Row(
      //       mainAxisAlignment: MainAxisAlignment.spaceAround,
      //       children: [
      //         _widgetOptions.elementAt(_currentIndex),
      //         ElevatedButton(
      //             child: Text('Sign Out'),
      //             onPressed: () async {
      //               await FirebaseAuth.instance.signOut();
      //               // setState(() {});
      //             }),
      //       ],
      //     ),
      //   ],
      // )),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        fixedColor: Colors.green,
        // type: BottomNavigationBarType.shifting,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            title: Text('Home'),
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_sharp),
            title: Text('Collection Centres'),
            backgroundColor: Colors.pink,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.refresh),
            title: Text('Returns'),
            backgroundColor: Colors.green,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            title: Text('Profile and Points'),
            backgroundColor: Colors.red,
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

// class IndexScreen extends StatelessWidget {
//   const IndexScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//   }
// }
