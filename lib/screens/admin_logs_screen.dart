import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:camelia/models/services/error_handler_service.dart';
import 'package:camelia/models/services/logging_service.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  final LoggingService _loggingService = LoggingService();
  final ErrorHandlerService _errorHandler = ErrorHandlerService();
  final TextEditingController _searchController = TextEditingController();

  // Filtres
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String _selectedSeverity = 'all';
  String _selectedCategory = 'all';
  String _searchQuery = '';

  // Statistiques
  Map<String, int> _errorStats = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadErrorStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadErrorStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final stats = await _loggingService.getErrorStats(7);
      setState(() {
        _errorStats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() => _isLoadingStats = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorHandler.handleError(e))),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Logs Administrateur',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadErrorStats,
            tooltip: 'Actualiser les statistiques',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistiques
          _buildStatsSection(),

          // Filtres
          _buildFiltersSection(),

          // Liste des logs
          Expanded(
            child: _buildLogsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_isLoadingStats) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques des 7 derniers jours',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildStatCard(
                'Total Erreurs',
                _errorStats.values.fold(0, (a, b) => a + b).toString(),
                Icons.error,
                Colors.red,
              ),
              ..._errorStats.entries.map((entry) => _buildStatCard(
                entry.key,
                entry.value.toString(),
                Icons.warning,
                Colors.orange,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher dans les logs...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.date_range),
                label: Text(
                  '${DateFormat('dd/MM').format(_startDate)} - ${DateFormat('dd/MM').format(_endDate)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSeverity,
                  decoration: const InputDecoration(
                    labelText: 'Sévérité',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Toutes')),
                    DropdownMenuItem(value: 'error', child: Text('Erreurs')),
                    DropdownMenuItem(value: 'warning', child: Text('Avertissements')),
                    DropdownMenuItem(value: 'info', child: Text('Informations')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedSeverity = value ?? 'all');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Toutes')),
                    DropdownMenuItem(value: 'auth', child: Text('Authentification')),
                    DropdownMenuItem(value: 'firestore', child: Text('Base de données')),
                    DropdownMenuItem(value: 'network', child: Text('Réseau')),
                    DropdownMenuItem(value: 'generic', child: Text('Général')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategory = value ?? 'all');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _loggingService.getLogsForAdmin(
        limitDays: _endDate.difference(_startDate).inDays,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        // Appliquer les filtres
        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // Filtre de recherche
          if (_searchQuery.isNotEmpty) {
            final title = (data['title'] ?? '').toString().toLowerCase();
            final message = (data['technicalMessage'] ?? '').toString().toLowerCase();
            final category = (data['category'] ?? '').toString().toLowerCase();

            if (!title.contains(_searchQuery) &&
                !message.contains(_searchQuery) &&
                !category.contains(_searchQuery)) {
              return false;
            }
          }

          // Filtre de sévérité
          if (_selectedSeverity != 'all') {
            if (data['severity'] != _selectedSeverity) return false;
          }

          // Filtre de catégorie
          if (_selectedCategory != 'all') {
            if (data['category'] != _selectedCategory) return false;
          }

          // Filtre de date
          final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
          if (timestamp != null) {
            if (timestamp.isBefore(_startDate) || timestamp.isAfter(_endDate)) {
              return false;
            }
          }

          return true;
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(
            child: Text('Aucun log trouvé avec les filtres actuels'),
          );
        }

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildLogItem(data);
          },
        );
      },
    );
  }

  Widget _buildLogItem(Map<String, dynamic> data) {
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final severity = data['severity'] ?? 'unknown';
    final category = data['category'] ?? 'unknown';
    final title = data['title'] ?? 'Sans titre';
    final technicalMessage = data['technicalMessage'] ?? '';
    final userId = data['userId'] ?? 'N/A';
    final stackTrace = data['stackTrace'] ?? '';

    Color severityColor;
    IconData severityIcon;

    switch (severity) {
      case 'error':
        severityColor = Colors.red;
        severityIcon = Icons.error;
        break;
      case 'warning':
        severityColor = Colors.orange;
        severityIcon = Icons.warning;
        break;
      case 'info':
        severityColor = Colors.blue;
        severityIcon = Icons.info;
        break;
      default:
        severityColor = Colors.grey;
        severityIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: severityColor.withValues(alpha: 0.2),
          child: Icon(severityIcon, color: severityColor, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: severityColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              timestamp != null
                  ? DateFormat('dd/MM/yyyy HH:mm:ss').format(timestamp)
                  : 'Date inconnue',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            Row(
              children: [
                Chip(
                  label: Text(
                    category,
                    style: GoogleFonts.poppins(fontSize: 10),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Text(
                  'User: ${userId.substring(0, min(8, userId.length))}...',
                  style: GoogleFonts.poppins(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message technique:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  technicalMessage,
                  style: GoogleFonts.poppins(
                    
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                if (stackTrace.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Stack Trace:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        stackTrace,
                        style: GoogleFonts.poppins(
                         
                          fontSize: 10,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;
}