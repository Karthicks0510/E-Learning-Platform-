// offer_of_the_day_dialog.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

class OfferOfTheDayDialog extends StatefulWidget {
  @override
  _OfferOfTheDayDialogState createState() => _OfferOfTheDayDialogState();
}

class _OfferOfTheDayDialogState extends State<OfferOfTheDayDialog> {
  String _offerTitle = 'Loading...';
  String _offerReward = '';
  String _offerCurrency = '';

  @override
  void initState() {
    super.initState();
    _fetchOfferOfTheDay();
  }

  Future<void> _fetchOfferOfTheDay() async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('rewards', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final DocumentSnapshot doc = querySnapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _offerTitle = data['title'] ?? 'No Title';
          _offerReward = data['rewards'] ?? 'N/A';
          _offerCurrency = data['currency'] ?? '';
        });
      } else {
        setState(() {
          _offerTitle = 'No offers today.';
        });
      }
    } catch (e) {
      print('Error fetching offer of the day: $e');
      setState(() {
        _offerTitle = 'Error loading offer.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.deepPurple[100], // Light purple background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer, color: Colors.deepPurple), // Offer Icon
          SizedBox(width: 8),
          Text(
            'Offer of the Day!',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            FadeInDown( // Animation for title
              child: Row(
                children: [
                  Icon(Icons.title, color: Colors.purple),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _offerTitle,
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Colors.purple[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            FadeInUp( // Animation for rewards
              child: Row(
                children: [
                  Icon(Icons.diamond, color: Colors.amber), // Reward Icon
                  SizedBox(width: 8),
                  Text(
                    'Reward: $_offerReward $_offerCurrency',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.amber[800],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            FadeIn(
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Valid Today Only!',
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.close, color: Colors.white),
          label: Text(
            'Close',
            style: GoogleFonts.raleway(
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple, // Corrected line
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ],
    );
  }
}