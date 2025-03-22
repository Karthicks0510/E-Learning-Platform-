import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class OfferOfTheDayDialog extends StatefulWidget {
  @override
  _OfferOfTheDayDialogState createState() => _OfferOfTheDayDialogState();
}

class _OfferOfTheDayDialogState extends State<OfferOfTheDayDialog> {
  String _offerTitle = 'Loading...';
  String _offerReward = '';
  String _offerCurrency = '';
  String _offerDescription = '';
  List<String> _offerAttachments = [];

  @override
  void initState() {
    super.initState();
    _fetchOfferOfTheDay();
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }

  void _fetchOfferOfTheDay() {
    FirebaseFirestore.instance
        .collection('posts')
        .orderBy('rewards', descending: true)
        .limit(1)
        .snapshots() // Use snapshots() for real-time updates
        .listen((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        final DocumentSnapshot doc = querySnapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _offerTitle = data['title'] ?? 'No Title';
          _offerReward = data['rewards']?.toString() ?? 'N/A'; // Convert to string
          _offerCurrency = data['currency'] ?? '';
          _offerDescription = data['description'] ?? 'No Description';
          _offerAttachments = List<String>.from(data['attachments'] ?? []);
        });
      } else {
        setState(() {
          _offerTitle = 'No offers today.';
        });
      }
    }, onError: (error) {
      print('Error fetching offer of the day: $error');
      setState(() {
        _offerTitle = 'Error loading offer.';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.deepPurple[50], // Light purple background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer, color: Colors.deepPurple),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FadeInDown(
              child: ListTile(
                leading: Icon(Icons.title, color: Colors.purple),
                title: Text(
                  _offerTitle,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.purple[800],
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            FadeInUp(
              child: ListTile(
                leading: Icon(Icons.diamond, color: Colors.amber),
                title: Text(
                  'Reward: $_offerReward $_offerCurrency',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.amber[800],
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            FadeIn(
              child: ListTile(
                leading: Icon(Icons.description, color: Colors.blue),
                title: Text(
                  _offerDescription,
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            if (_offerAttachments.isNotEmpty)
              FadeIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attachments:',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Column(
                      children: _offerAttachments
                          .asMap()
                          .entries
                          .map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'File ${entry.key + 1}', // Display "File 1", "File 2", etc.
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.remove_red_eye),
                              onPressed: () => _launchURL(entry.value),
                            ),
                          ],
                        ),
                      ))
                          .toList(),
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
            backgroundColor: Colors.deepPurple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ],
    );
  }
}