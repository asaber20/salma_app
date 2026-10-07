import 'package:flutter/material.dart';
import 'chat_physical_inventory_screen.dart';
import 'login_otp_screen.dart';

class ConversationsScreen extends StatefulWidget {
  final String employeeId;

  const ConversationsScreen({super.key, required this.employeeId});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allAgents = [
    {
      'name': 'Physical Inventory Agent',
      'preview': 'Tap to open physical inventory updates...',
      'time': 'Live 🟢',
      'image': 'assets/images/salma_physical_inventory_avatar.jpeg',
      'isAvailable': true,
    },
    {
      'name': 'Profitability Analysis Agent',
      'preview': 'Profitability analysis and margin reporting assistant...',
      'time': 'Under development ⏳',
      'image': 'assets/images/Salama_Revenue_Avatar.jpeg',
      'isAvailable': false,
    },
    {
      'name': 'PO Approval Agent',
      'preview': 'Purchase order approval assistant...',
      'time': 'Under development ⏳',
      'image': 'assets/images/Salma_PO_approval_avatar.jpeg',
      'isAvailable': false,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAvatarImageViewer(BuildContext context, String imagePath, String agentName) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          agentName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  InteractiveViewer(
                    child: Hero(
                      tag: imagePath,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAgents = _allAgents.where((agent) {
      final name = agent['name'].toString().toLowerCase();
      final preview = agent['preview'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || preview.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header with "Chats" title and logout option
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Chats",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111111),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Color(0xFF303489)),
                    tooltip: 'Logout',
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginOtpScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: Colors.grey.shade500, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Conversations List
            Expanded(
              child: filteredAgents.isEmpty
                  ? Center(
                      child: Text(
                        "No chats found",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredAgents.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, indent: 76, color: Color(0xFFEEEEEE)),
                      itemBuilder: (context, index) {
                        final agent = filteredAgents[index];
                        final bool isAvailable = agent['isAvailable'] ?? false;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: GestureDetector(
                            onTap: () {
                              if (agent['image'] != null) {
                                _showAvatarImageViewer(context, agent['image'], agent['name']);
                              }
                            },
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: agent['image'] != null
                                  ? AssetImage(agent['image']) as ImageProvider
                                  : null,
                              child: agent['image'] == null
                                  ? const Icon(
                                      Icons.smart_toy_rounded,
                                      color: Color(0xFF303489),
                                      size: 26,
                                    )
                                  : null,
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  agent['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF33333D),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                agent['time'],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isAvailable ? const Color(0xFF00BFA5) : Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              agent['preview'],
                              style: TextStyle(
                                fontSize: 13,
                                color: isAvailable ? Colors.grey.shade700 : Colors.grey.shade400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          onTap: () {
                            if (isAvailable) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatPhysicalInventoryScreen(
                                    employeeId: widget.employeeId,
                                    triggerChatStart: true,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("${agent['name']} is coming soon!"),
                                  backgroundColor: const Color(0xFF303489),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
