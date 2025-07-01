import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_item.dart';
import '../services/api_service.dart';
import '../utils/dialog_utils.dart';

enum FilterOption { semua, hariIni, kemarin }

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  List<NotificationItem> _allNotifikasi = [];
  List<NotificationItem> _filteredNotifikasi = [];

  FilterOption _selectedFilter = FilterOption.semua;
  bool _isLoading = true;

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ApiService.getAllNotifications();
      _allNotifikasi = data;
      _applyFilter();
    } catch (e) {
      print("Gagal ambil notifikasi: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _applyFilter() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    List<NotificationItem> result = [];

    for (var item in _allNotifikasi) {
      final localDate = item.createdAt.toLocal();
      final tanggal = DateTime(localDate.year, localDate.month, localDate.day);

      switch (_selectedFilter) {
        case FilterOption.hariIni:
          if (tanggal == today) result.add(item);
          break;
        case FilterOption.kemarin:
          if (tanggal == yesterday) result.add(item);
          break;
        case FilterOption.semua:
          result.add(item);
          break;
      }
    }

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _filteredNotifikasi = result;
    });
  }

  String _formatWaktu(DateTime waktu) {
    final local = waktu.toLocal();
    final now = DateTime.now();
    if (local.day == now.day &&
        local.month == now.month &&
        local.year == now.year) {
      return DateFormat.Hm().format(local);
    } else {
      return DateFormat.E('id_ID').format(local).toUpperCase() +
          ' ${local.day} ${DateFormat.MMM('id_ID').format(local).toUpperCase()}';
    }
  }

  Future<void> _tandaiSemuaDibaca() async {
    try {
      await ApiService.markAllNotificationsAsRead();
      await _loadNotifications();
    } catch (e) {
      print("Gagal tandai semua dibaca: $e");
    }
  }

  Future<void> _hapusSemua() async {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          ),
          contentPadding: EdgeInsets.fromLTRB(
            isTablet ? 32 : 24,
            isTablet ? 32 : 24,
            isTablet ? 32 : 24,
            isTablet ? 16 : 12,
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 400 : 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hapus Semua Notifikasi?',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isTablet ? 16 : 12),
                Text(
                  'Yakin ingin menghapus semua notifikasi?',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isTablet ? 32 : 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 16 : 12,
                          vertical: isTablet ? 12 : 8,
                        ),
                        child: Text(
                          'Batal',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: isTablet ? 16 : 14,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        Navigator.of(dialogContext).pop();
                        try {
                          await ApiService.deleteAllNotifications();
                          setState(() {
                            _allNotifikasi.clear();
                            _filteredNotifikasi.clear();
                          });
                          showAllNotificationDeletedPopup(context);
                        } catch (e) {
                          _showErrorSnackBar(
                            "Gagal hapus semua notifikasi: $e",
                          );
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 16 : 12,
                          vertical: isTablet ? 12 : 8,
                        ),
                        child: Text(
                          'Hapus',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                            fontSize: isTablet ? 16 : 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Wrap(
      spacing: isTablet ? 12 : 8,
      runSpacing: isTablet ? 8 : 4,
      children:
          FilterOption.values.map((option) {
            String label;
            switch (option) {
              case FilterOption.semua:
                label = "Semua";
                break;
              case FilterOption.hariIni:
                label = "Hari Ini";
                break;
              case FilterOption.kemarin:
                label = "Kemarin";
                break;
            }
            return ChoiceChip(
              label: Text(
                label,
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
              selected: _selectedFilter == option,
              onSelected: (_) {
                setState(() {
                  _selectedFilter = option;
                });
                _applyFilter();
              },
              selectedColor: Colors.blue.shade100,
              backgroundColor: Colors.grey.shade200,
              labelStyle: TextStyle(
                color:
                    _selectedFilter == option
                        ? Colors.blue.shade800
                        : Colors.black,
                fontSize: isTablet ? 16 : 14,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : 12,
                vertical: isTablet ? 12 : 8,
              ),
            );
          }).toList(),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final icon =
        item.type == 'suhu' ? Icons.thermostat : Icons.water_drop_outlined;
    final iconColor = item.type == 'suhu' ? Colors.green : Colors.blue;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 700 : double.infinity),
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          ),
          margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
          elevation: isTablet ? 2 : 1.5,
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.1),
                  radius: isTablet ? 24 : 20,
                  child: Icon(icon, color: iconColor, size: isTablet ? 28 : 24),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              "Notifikasi ${item.type == 'suhu' ? 'Suhu' : 'Level Air'}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isTablet ? 16 : 14,
                              ),
                            ),
                          ),
                          SizedBox(width: isTablet ? 12 : 8),
                          Text(
                            _formatWaktu(item.createdAt),
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 8 : 6),
                      Text(
                        item.message,
                        style: TextStyle(
                          fontSize: isTablet ? 15 : 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 32 : 16,
            vertical: isTablet ? 32 : 24,
          ),
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        "Notifikasi",
                        style: TextStyle(
                          fontSize: isTablet ? 32 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isTablet ? 16 : 12),

                      // Filter Chips
                      _buildFilterChips(),
                      SizedBox(height: isTablet ? 16 : 12),

                      // Action Buttons
                      isLandscape && !isTablet
                          ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                TextButton.icon(
                                  onPressed: _tandaiSemuaDibaca,
                                  icon: const Icon(Icons.done_all),
                                  label: const Text("Tandai dibaca"),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                                SizedBox(width: isTablet ? 16 : 8),
                                TextButton.icon(
                                  onPressed: _hapusSemua,
                                  icon: const Icon(Icons.delete_forever),
                                  label: const Text("Hapus semua"),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: _tandaiSemuaDibaca,
                                icon: const Icon(Icons.done_all),
                                label: const Text("Tandai dibaca"),
                                style: TextButton.styleFrom(
                                  textStyle: TextStyle(
                                    fontSize: isTablet ? 16 : 14,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _hapusSemua,
                                icon: const Icon(Icons.delete_forever),
                                label: const Text("Hapus semua"),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  textStyle: TextStyle(
                                    fontSize: isTablet ? 16 : 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      SizedBox(height: isTablet ? 24 : 16),

                      // Notification List
                      Expanded(
                        child:
                            _filteredNotifikasi.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.notifications_none,
                                        size: isTablet ? 80 : 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      SizedBox(height: isTablet ? 16 : 12),
                                      Text(
                                        "Belum ada notifikasi.",
                                        style: TextStyle(
                                          fontSize: isTablet ? 18 : 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: _filteredNotifikasi.length,
                                  padding: EdgeInsets.only(
                                    bottom: isTablet ? 24 : 16,
                                  ),
                                  itemBuilder: (context, index) {
                                    return _buildNotificationCard(
                                      _filteredNotifikasi[index],
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
