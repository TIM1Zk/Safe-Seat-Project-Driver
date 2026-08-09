import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_project/core/network/api_service.dart';
import 'package:intl/intl.dart';

class WalletHistoryPage extends StatefulWidget {
  final String phone;

  const WalletHistoryPage({super.key, required this.phone});

  @override
  State<WalletHistoryPage> createState() => _WalletHistoryPageState();
}

class _WalletHistoryPageState extends State<WalletHistoryPage> {
  bool _isLoading = true;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final response = await ApiService.get('/wallets/${widget.phone}/transactions');

      if (response.statusCode == 200) {
        setState(() {
          _transactions = response.data;
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load transactions");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('โหลดข้อมูลล้มเหลว: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalWithdraw = _transactions
        .where((tx) => tx['type'] == 'withdraw')
        .fold(0.0, (sum, tx) => sum + (tx['amount'] ?? 0).toDouble());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.black))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.black,
                              size: 26,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Text(
                            "ประวัติการทำธุรกรรม",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 2,
                        color: Colors.grey.withOpacity(0.2),
                      ),
                      const SizedBox(height: 24),

                      // 2. TOTAL Withdraw Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E1E1E), Color(0xFF3A3A3A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "ยอดการถอนเงินสะสมทั้งหมด",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "฿${totalWithdraw.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. Filter Pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterPill("7 วันล่าสุด"),
                            const SizedBox(width: 10),
                            _buildFilterPill("สถานะ"),
                            const SizedBox(width: 10),
                            _buildFilterPill("ปฏิทิน", icon: Icons.calendar_today),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 4. Recent Transactions Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            "รายการล่าสุด",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            "ประวัติทั้งหมด",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 5. Transactions List
                      _transactions.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _transactions.length,
                              itemBuilder: (context, index) {
                                final tx = _transactions[index];
                                return _buildTransactionCard(tx);
                              },
                            ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 16, color: Colors.black87),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 20),
            const Text(
              "ยังไม่มีประวัติการทำรายการ",
              style: TextStyle(color: Colors.black45, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final DateTime createdAt = DateTime.parse(tx['created_at']).toLocal();
    final String formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(createdAt);
    final double amount = (tx['amount'] ?? 0).toDouble();
    final String status = tx['status'] == 'success' ? 'สำเร็จ' : 'รอดำเนินการ';
    final Color statusColor = tx['status'] == 'success' ? const Color(0xFF22C55E) : Colors.orange;

    final bool isWithdraw = tx['type'] == 'withdraw';
    final String txTitle = isWithdraw ? "ถอนเงิน (Withdrawal)" : "รายได้จากการให้บริการ (Income)";
    final String amountText = "${isWithdraw ? '-' : '+'} ฿${amount.toStringAsFixed(2)}";
    final Color amountColor = isWithdraw ? Colors.redAccent : const Color(0xFF22C55E);

    final Widget iconWidget = isWithdraw
        ? Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF4A154B), // SCB Purple
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.account_balance_outlined, color: Colors.amber, size: 24),
                Text(
                  "SCB",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        : Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.15), // Light green background
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Color(0xFF22C55E),
              size: 28,
            ),
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          iconWidget,
          const SizedBox(width: 16),
          // Transaction Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amountText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  txTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isWithdraw) ...[
                  const SizedBox(height: 2),
                  const Text(
                    "ธนาคารไทยพาณิชย์ **** 1234",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
