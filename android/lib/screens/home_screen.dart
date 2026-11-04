import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final String phoneNumber;
  const HomeScreen({super.key, required this.phoneNumber});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _accountData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAccountDetails();
  }

  Future<void> _fetchAccountDetails() async {
    final data = await _apiService.getAccountDetails(widget.phoneNumber);
    setState(() {
      _accountData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mytel Account')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accountData == null
              ? const Center(child: Text('Data not found'))
              : ListView.builder(
                  itemCount: (_accountData?['result'] as List?)?.length ?? 0,
                  itemBuilder: (context, index) {
                    final account = _accountData?['result'][index];
                    final balance = account?['mainBalance'];
                    final msisdn = account?['msisdn'];
                    
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('Phone: $msisdn'),
                        subtitle: Text('Balance: ${balance?['main']['amount']} ${balance?['main']['unit']}'),
                      ),
                    );
                  },
                ),
    );
  }
}
