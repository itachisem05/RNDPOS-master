import 'package:flutter/material.dart';
import 'package:usa/API/api_service.dart';
import 'package:usa/screens/menu_screen.dart';
import 'package:usa/widgets/app_bar.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  late final ApiService _apiService;
  bool isLoading = true;
  Map<String, dynamic> contactData = {};

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _getContactUs();
  }

  void _getContactUs() async {
    setState(() {
      isLoading = true; // Start loading
    });

    try {
      // Fetch data from the API
      var data = await _apiService.getContactUs();

      // Update the state with the contact information
      setState(() {
        contactData = data; // Set contactData directly
      });
    } catch (e) {
      print('An error occurred: $e');
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MenuScreen(),
      appBar: const CustomAppBar(title: 'Support'),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FAQ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const ExpansionTile(
              title: Text('What personal information does R&D POS collect through the mobile application?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: Color(0xFF00255D),
                  )),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text('R&D POS collects personal information that you voluntarily provide when using interactive features, such as quizzes or surveys. This may include your name, email address, and any other information you choose to share. We ensure that this information is stored securely and used to enhance your experience.',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 15.0,
                        color: Color(0xFF00355E),
                      )),
                ),
              ],
            ),
            const ExpansionTile(
              title: Text('How does R&D POS use my personal information?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: Color(0xFF00255D),
                  )),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text('We use your personal information to respond to your inquiries, provide requested information, personalize your experience, and improve our services. We may also send you e-newsletters or notifications if you have opted to receive them. Your information is never sold to third parties.',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 15.0,
                        color: Color(0xFF00355E),
                      )),
                ),
              ],
            ),
            const ExpansionTile(
              title: Text(
                  'Are my personal details safe when using the R&D POS mobile application?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: Color(0xFF00255D),
                  )),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text(
                      'While we take measures to protect your personal information, no method of transmission over the Internet is completely secure. We implement various security protocols, but we cannot guarantee absolute protection. For any concerns, please contact us at harry.patel@randdpos.com.',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 15.0,
                        color: Color(0xFF00355E),
                      )),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Contact',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00355E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Head Office',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00355E),
              ),
            ),
            const SizedBox(height: 8),
            contactData.isNotEmpty
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                        text: '${contactData['fullAddress']}, ',
                        style: const TextStyle(
                          fontFamily: 'Inter Semibold',
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF00355E),
                        ),
                      ),
                      TextSpan(
                        text: '${contactData['city']}, ',
                        style: const TextStyle(
                          fontFamily: 'Inter Light',
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF00355E),
                        ),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                        text: '${contactData['state']} ',
                        style: const TextStyle(
                          fontFamily: 'Inter Semibold',
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF00355E),
                        ),
                      ),
                      TextSpan(
                        text: '${contactData['zipCode']}',
                        style: const TextStyle(
                          fontFamily: 'Inter Light',
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF00355E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      const TextSpan(
                        text: 'Phone: ',
                        style: TextStyle(
                          fontFamily: 'Inter Semibold',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00355E),
                        ),
                      ),
                      TextSpan(
                        text: contactData['phone'] ?? 'Not provided',
                        style: const TextStyle(
                          fontFamily: 'Inter Light',
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF00355E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      const TextSpan(
                        text: 'Email: ',
                        style: TextStyle(
                          fontFamily: 'Inter Semibold',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00355E),
                        ),
                      ),
                      TextSpan(
                        text: contactData['email'] ?? 'Not provided',
                        style: const TextStyle(
                          fontFamily: 'Inter Light',
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF00355E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      const TextSpan(
                        text: 'Website: ',
                        style: TextStyle(
                          fontFamily: 'Inter Semibold',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00355E),
                        ),
                      ),
                      TextSpan(
                        text: contactData['webSite'] ?? 'Not provided',
                        style: const TextStyle(
                          fontFamily: 'Inter Light',
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF00355E),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            )
                : const Text('No contact information available'),
          ],
        ),
      ),
    );
  }
}
