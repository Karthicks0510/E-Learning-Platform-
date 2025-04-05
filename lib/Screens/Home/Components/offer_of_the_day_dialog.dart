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
  bool _isLoading = true;

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

  Future<void> _fetchOfferOfTheDay() async {
    try {
      FirebaseFirestore.instance
          .collection('posts')
          .where('status', isEqualTo: 'pending')
          .get() // Fetch all pending posts
          .then((QuerySnapshot querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          List<DocumentSnapshot> pendingPosts = querySnapshot.docs;

          // Sort the posts by rewards (descending)
          pendingPosts.sort((a, b) {
            double rewardA = (a.data() as Map<String, dynamic>)['rewards'] is double
                ? (a.data() as Map<String, dynamic>)['rewards']
                : (a.data() as Map<String, dynamic>)['rewards'] is int
                ? (a.data() as Map<String, dynamic>)['rewards'].toDouble()
                : 0.0;
            double rewardB = (b.data() as Map<String, dynamic>)['rewards'] is double
                ? (b.data() as Map<String, dynamic>)['rewards']
                : (b.data() as Map<String, dynamic>)['rewards'] is int
                ? (b.data() as Map<String, dynamic>)['rewards'].toDouble()
                : 0.0;
            return rewardB.compareTo(rewardA); // Descending order
          });

          // Get the post with the highest reward
          DocumentSnapshot highestRewardPost = pendingPosts.first;
          final data = highestRewardPost.data() as Map<String, dynamic>;

          double reward = (data['rewards'] is double)
              ? data['rewards']
              : (data['rewards'] is int)
              ? data['rewards'].toDouble()
              : 0.0;

          setState(() {
            _offerTitle = data['title'] ?? 'No Title';
            _offerReward = reward.toStringAsFixed(2);
            _offerCurrency = data['currency'] ?? '';
            _offerDescription = data['description'] ?? 'No Description';
            _offerAttachments = List<String>.from(data['attachments'] ?? []);
            _isLoading = false;
          });
        } else {
          setState(() {
            _offerTitle = 'No offers today.';
            _isLoading = false;
          });
        }
      }).catchError((error) {
        print('Error fetching offer of the day: $error');
        setState(() {
          _offerTitle = 'Error loading offer.';
          _isLoading = false;
        });
      });
    } catch (e) {
      print('Error fetching offer of the day: $e');
      setState(() {
        _offerTitle = 'Error loading offer.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.deepPurple[50],
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
      content: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'File ${entry.key + 1}',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.remove_red_eye),
                              onPressed: () =>
                                  _launchURL(entry.value),
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