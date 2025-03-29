import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_details_page.dart';
import 'package:animate_do/animate_do.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;

  SearchResultsPage({required this.query});

  @override
  _SearchResultsPageState createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  double _minPrice = 0;
  double _maxPrice = 1000;
  String _selectedCurrency = 'All';
  String _selectedLanguage = 'All';
  List<DocumentSnapshot> _initialResults = [];
  List<DocumentSnapshot> _filteredDocs = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialResults();
  }

  void _fetchInitialResults() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .get();

    _initialResults = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final title = data['title']?.toString().toLowerCase() ?? '';
      final description = data['description']?.toString().toLowerCase() ?? '';

      return title.contains(widget.query.toLowerCase()) ||
          description.contains(widget.query.toLowerCase());
    }).toList();

    setState(() {
      _filteredDocs = _initialResults;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results for "${widget.query}"'),
        backgroundColor: Colors.purple,
      ),
      body: _initialResults.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildFilterOptions(),
          Expanded(
            child: _buildResultList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: [
          _buildFilterSlider(
            title: 'Min Price',
            value: _minPrice,
            onChanged: (value) {
              setState(() {
                _minPrice = value;
                _applyFilters();
              });
            },
          ),
          _buildFilterSlider(
            title: 'Max Price',
            value: _maxPrice,
            onChanged: (value) {
              setState(() {
                _maxPrice = value;
                _applyFilters();
              });
            },
          ),
          _buildCurrencyDropdown(),
          _buildLanguageDropdown(),
        ],
      ),
    );
  }

  Widget _buildFilterSlider({
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$title: ${value.toStringAsFixed(0)}'),
          SizedBox(width: 8.0),
          Slider(
            value: value,
            min: 0,
            max: 1000,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Currency: '),
          DropdownButton<String>(
            value: _selectedCurrency,
            onChanged: (value) {
              setState(() {
                _selectedCurrency = value!;
                _applyFilters();
              });
            },
            items: ['All', 'USD', 'EUR', 'GBP']
                .map((currency) =>
                DropdownMenuItem(
                  value: currency,
                  child: Text(currency),
                ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Language: '),
          DropdownButton<String>(
            value: _selectedLanguage,
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value!;
                _applyFilters();
              });
            },
            items: ['All', 'English', 'Spanish', 'French', 'Hindi','Tamil','Telugu','Kannada','Malayalam','Chinese','Japanese','Korean']
                .map((language) =>
                DropdownMenuItem(
                  value: language,
                  child: Text(language),
                ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultList() {
    if (_filteredDocs.isEmpty) {
      return Center(
          child: Text('No matching posts found with applied filters.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return ListView.builder(
            itemCount: _filteredDocs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot document = _filteredDocs[index];
              Map<String, dynamic> data =
              document.data() as Map<String, dynamic>;
              return _buildAnimatedCard(0, document, data);
            },
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _filteredDocs.map((document) {
                Map<String, dynamic> data =
                document.data() as Map<String, dynamic>;
                return _buildAnimatedCard(
                    constraints.maxWidth > 600 ? 300.0 : 200.0, document, data);
              }).toList(),
            ),
          );
        }
      },
    );
  }

  Widget _buildAnimatedCard(double cardWidth, DocumentSnapshot document,
      Map<String, dynamic> data) {
    return StatefulBuilder(
        builder: (context, setState) {
      bool isHovered = false;
      return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedScale(
          duration: Duration(milliseconds: 200),
    scale: isHovered ? 1.05 : 1.0,
    child: AnimatedContainer(
    duration: Duration(milliseconds: 200),
    width: cardWidth > 0 ? cardWidth : MediaQuery.of(context).size.width * 0.9,
    margin: EdgeInsets.symmetric(vertical: 8, horizontal: cardWidth > 0 ? 0 : MediaQuery.of(context).size.width * 0.05),
    decoration: BoxDecoration(
    gradient: LinearGradient(
    colors: isHovered
    ? [Colors.blue[600]!, Colors.purple[600]!]
        : [Colors.blue[400]!, Colors.purple[400]!],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
    BoxShadow(
    color: Colors.grey.withOpacity(isHovered ? 0.7 : 0.5),
    spreadRadius: isHovered ? 3 : 2,
    blurRadius: isHovered ? 7 : 5,
    offset: Offset(0, 3),
    ),
    ],
    ),
    child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    FadeInLeft(
    child: Text(
    data['title']?? 'No Title',
      style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    ),
    ),
            SizedBox(height: 8),
            FadeInLeft(
              child: Text(
                'Rewards: ${data['rewards'] ?? 'N/A'} ${data['currency'] ?? ''}',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PostDetailsPage(postId: document.id),
                    ),
                  );
                },
                child: Text('Read More'),
              ),
            ),
            ],
          ),
      ),
          ),
          ),
          );
        },
    );
  }

  void _applyFilters() {
    setState(() {
      _filteredDocs = _initialResults.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        dynamic rewards = data['rewards'];
        double rewardsValue = 0.0;

        if (rewards is String) {
          rewardsValue = double.tryParse(rewards) ?? 0.0;
        } else if (rewards is num) {
          rewardsValue = rewards.toDouble();
        }

        final docCurrency = data['currency']?.toString() ?? '';
        final preferredLanguages = data['preferredLanguages']; // Changed to preferredLanguages

        bool languageMatch = true;
        if (_selectedLanguage != 'All') {
          if (preferredLanguages is List) {
            languageMatch = preferredLanguages.contains(_selectedLanguage);
          } else {
            languageMatch = preferredLanguages == _selectedLanguage;
          }
        }

        return rewardsValue >= _minPrice &&
            rewardsValue <= _maxPrice &&
            (_selectedCurrency == 'All' || docCurrency == _selectedCurrency) &&
            languageMatch; // Use languageMatch variable
      }).toList();
    });
  }
}