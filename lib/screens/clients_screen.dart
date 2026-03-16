import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/client.dart';
import '../services/firestore_service.dart';
import '../theme.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  List<Client> _filterClients(List<Client> clients) {
    return clients
        .where(
          (c) =>
              c.name.toLowerCase().contains(_search.toLowerCase()) ||
              c.phone.contains(_search),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<List<Client>>(
              stream: FirestoreService.clientsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar clientes.',
                      style: GoogleFonts.lato(color: AppTheme.error),
                    ),
                  );
                }

                final clients = snapshot.data ?? [];
                final filtered = _filterClients(clients);

                if (filtered.isEmpty) {
                  return _buildEmpty();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildClientCard(filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add),
        label: Text('Nova Cliente', style: GoogleFonts.lato()),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppTheme.rosePrimary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _search = v),
        style: GoogleFonts.lato(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar cliente...',
          hintStyle: GoogleFonts.lato(color: Colors.white60),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white54),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 72, color: AppTheme.roseLight),
          const SizedBox(height: 16),
          Text(
            'Nenhuma cliente cadastrada',
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.textLight,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no botão abaixo para adicionar',
            style: GoogleFonts.lato(color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(Client client) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.roseLight,
          radius: 24,
          child: Text(
            client.name[0].toUpperCase(),
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.rosePrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          client.name,
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, size: 14, color: AppTheme.textLight),
                const SizedBox(width: 4),
                Text(client.phone, style: GoogleFonts.lato(fontSize: 13)),
              ],
            ),
            if (client.email != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.email, size: 14, color: AppTheme.textLight),
                  const SizedBox(width: 4),
                  Text(client.email!, style: GoogleFonts.lato(fontSize: 13)),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'edit') _openForm(client: client);
            if (val == 'delete') _confirmDelete(client);
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, color: AppTheme.rosePrimary),
                  const SizedBox(width: 8),
                  Text('Editar', style: GoogleFonts.lato()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: AppTheme.error),
                  const SizedBox(width: 8),
                  Text(
                    'Excluir',
                    style: GoogleFonts.lato(color: AppTheme.error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openForm({Client? client}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClientForm(client: client),
    );
  }

  void _confirmDelete(Client client) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Excluir cliente?',
          style: GoogleFonts.playfairDisplay(),
        ),
        content: Text(
          'Esta ação não pode ser desfeita.',
          style: GoogleFonts.lato(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.lato()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              await FirestoreService.deleteClient(client.id);
              if (mounted) Navigator.pop(context);
            },
            child: Text('Excluir', style: GoogleFonts.lato()),
          ),
        ],
      ),
    );
  }
}

class _ClientForm extends StatefulWidget {
  final Client? client;

  const _ClientForm({this.client});

  @override
  State<_ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<_ClientForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.client?.name);
  late final _phoneCtrl = TextEditingController(text: widget.client?.phone);
  late final _emailCtrl = TextEditingController(text: widget.client?.email);
  late final _notesCtrl = TextEditingController(text: widget.client?.notes);
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.client == null ? 'Nova Cliente' : 'Editar Cliente',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 20),
              _field(
                _nameCtrl,
                'Nome completo',
                Icons.person,
                required: true,
              ),
              const SizedBox(height: 12),
              _field(
                _phoneCtrl,
                'Telefone',
                Icons.phone,
                required: true,
                keyboard: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _field(
                _emailCtrl,
                'E-mail (opcional)',
                Icons.email,
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _field(
                _notesCtrl,
                'Observações (opcional)',
                Icons.notes,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(
                    _saving
                        ? 'Salvando...'
                        : (widget.client == null ? 'Cadastrar' : 'Salvar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.rosePrimary),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final client = Client(
        id: widget.client?.id ?? const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        createdAt: widget.client?.createdAt ?? DateTime.now(),
      );

      await FirestoreService.saveClient(client);

      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar cliente.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
