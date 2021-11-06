import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserPurchased extends StatefulWidget {
  const UserPurchased({Key? key}) : super(key: key);

  @override
  _UserPurchasedState createState() => _UserPurchasedState();
}

class _UserPurchasedState extends State<UserPurchased> {
  User? user = FirebaseAuth.instance.currentUser;

  final Stream<QuerySnapshot> _userItemsStream = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser?.uid)
      .collection('items_purchased')
      .where('deposit type', isNotEqualTo: 'reverse')
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _userItemsStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Error Occurred.');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            print('loading');
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView(
            shrinkWrap: true,
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data()! as Map<String, dynamic>;
              return Card(
                child: ListTile(
                    title: Text(data['qty'].toString() + ' x ' + data['brand']),
                    subtitle:
                        Text('Purchased: ' + data['date'].toDate().toString()),
                    onTap: () async {
                      // DateTime returnDate = DateTime.now();

                      print('Selected: ' +
                          data['brand'] +
                          ' ' +
                          data['qty'].toString());
                    }),
              );
            }).toList(),
          );
        });
  }
}
