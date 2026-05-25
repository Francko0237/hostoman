import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/shared/responsive_wrapper.dart';
import '../shared/pharmacie_theme.dart';
import '../Dashboard/listemedicament_service.dart';
import 'vente_libre_service.dart';

class VenteLibrePage extends StatefulWidget {
  const VenteLibrePage({super.key});

  @override
  State<VenteLibrePage> createState() => _VenteLibrePageState();
}

class _VenteLibrePageState extends State<VenteLibrePage> {
  final _medService = ListeMedicamentService(Supabase.instance.client);
  final _venteService = VenteLibreService(Supabase.instance.client);

  List<Map<String, dynamic>> _catalogue = [];
  final List<Map<String, dynamic>> _panier = [];
  bool _loading = true;
  bool _saving = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cat = await _medService.getAll(actifsSeulement: true);
      if (mounted) {
        setState(() {
          _catalogue = cat;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _ajouter(Map<String, dynamic> m) {
    final stock = (m['stock'] as num?)?.toInt() ?? 0;
    if (stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: PharmacieTheme.danger,
        content: Text('phar_vl_out_of_stock'.tr()),
      ));
      return;
    }
    final existant = _panier.indexWhere(
      (p) => p['id_medicament'] == m['id_medicament'],
    );
    setState(() {
      if (existant >= 0) {
        final q = (_panier[existant]['quantite'] as int) + 1;
        if (q > stock) return;
        _panier[existant]['quantite'] = q;
      } else {
        _panier.add({
          'id_medicament': m['id_medicament'],
          'nom_medicament': m['nom_medicament'],
          'prix_unitaire': (m['prix_unitaire'] as num).toDouble(),
          'quantite': 1,
          'posologie': '',
          'stock_max': stock,
        });
      }
    });
  }

  void _changerQte(int index, int delta) {
    setState(() {
      final p = _panier[index];
      final q = (p['quantite'] as int) + delta;
      final maxStock = (p['stock_max'] as int);
      if (q <= 0) {
        _panier.removeAt(index);
      } else if (q <= maxStock) {
        p['quantite'] = q;
      }
    });
  }

  void _retirer(int index) {
    setState(() => _panier.removeAt(index));
  }

  double get _total => _panier.fold(
        0,
        (sum, p) =>
            sum + (p['prix_unitaire'] as double) * (p['quantite'] as int),
      );

  Future<void> _valider() async {
    if (_panier.isEmpty) return;
    setState(() => _saving = true);
    try {
      final id = await _venteService.creerVente(lignes: _panier);
      if (mounted) {
        setState(() {
          _panier.clear();
        });
        await _load(); // recharger le stock
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: PharmacieTheme.success,
          content: Text(
            'phar_vl_success'.tr(namedArgs: {'id': '$id'}),
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: PharmacieTheme.danger,
          content: Text('phar_action_error'.tr()),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobile(),
      pc: _buildPc(),
    );
  }

  Widget _buildMobile() {
    return Scaffold(
      backgroundColor: PharmacieTheme.background,
      drawer: const PharmacieDrawer(
          activeRoute: '/Dashboard_Pharmacie/VenteLibre'),
      appBar: PharmacieAppBar(
        title: 'phar_vl_title'.tr(),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _buildBody(isMobile: true),
    );
  }

  Widget _buildPc() {
    return PharmaciePcLayout(
      activeRoute: '/Dashboard_Pharmacie/VenteLibre',
      breadcrumbKey: 'phar_breadcrumb_vente_libre',
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'phar_vl_title'.tr(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: PharmacieTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'phar_vl_subtitle'.tr(),
              style: const TextStyle(
                fontSize: 14,
                color: PharmacieTheme.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody(isMobile: false)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({required bool isMobile}) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: PharmacieTheme.primary),
      );
    }

    final filtered = _search.isEmpty
        ? _catalogue
        : _catalogue
            .where((m) => (m['nom_medicament'] ?? '')
                .toString()
                .toLowerCase()
                .contains(_search))
            .toList();

    if (isMobile) {
      // Mobile : catalogue dessus, panier flottant en bas
      return Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            child: Column(
              children: [
                _searchField(),
                const SizedBox(height: 12),
                Expanded(child: _catalogueList(filtered)),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _panierBar(),
          ),
        ],
      );
    }

    // PC : 2 colonnes (catalogue | panier)
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _searchField(),
              const SizedBox(height: 12),
              Expanded(child: _catalogueList(filtered)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 380,
          child: _panierPanel(),
        ),
      ],
    );
  }

  Widget _searchField() {
    return TextField(
      onChanged: (v) => setState(() => _search = v.toLowerCase().trim()),
      decoration: InputDecoration(
        hintText: 'phar_vl_search_hint'.tr(),
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PharmacieTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PharmacieTheme.border),
        ),
      ),
    );
  }

  Widget _catalogueList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return Center(child: Text('fiche_med_empty'.tr()));
    }
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final m = list[i];
        final stock = (m['stock'] as num?)?.toInt() ?? 0;
        final dispo = stock > 0;
        final prix = (m['prix_unitaire'] as num?)?.toDouble() ?? 0;
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: dispo ? () => _ajouter(m) : null,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PharmacieTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: PharmacieTheme.primary
                          .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.medication_outlined,
                      color: PharmacieTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (m['nom_medicament'] ?? '').toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: PharmacieTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if ((m['forme'] ?? '').toString().isNotEmpty)
                              m['forme'],
                            if ((m['dosage'] ?? '').toString().isNotEmpty)
                              m['dosage'],
                            'phar_stock_label'
                                .tr(namedArgs: {'stock': '$stock'}),
                          ].join(' • '),
                          style: const TextStyle(
                            fontSize: 11,
                            color: PharmacieTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'phar_amount_fcfa'.tr(namedArgs: {
                          'amount': prix.toStringAsFixed(0),
                        }),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: PharmacieTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      PharmacieStatusBadge(
                        text: dispo
                            ? 'fiche_med_badge_available'.tr()
                            : 'fiche_med_badge_unavailable'.tr(),
                        color: dispo
                            ? PharmacieTheme.success
                            : PharmacieTheme.danger,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _panierBar() {
    return Material(
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: PharmacieTheme.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart_outlined,
                    color: PharmacieTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'phar_vl_panier_count'.tr(
                    namedArgs: {'count': '${_panier.length}'},
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  'phar_amount_fcfa'.tr(
                    namedArgs: {'amount': _total.toStringAsFixed(0)},
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: PharmacieTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _panier.isEmpty || _saving
                        ? null
                        : () => _showPanierBottomSheet(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('phar_vl_view_panier'.tr()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _panier.isEmpty || _saving ? null : _valider,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text('phar_vl_validate'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PharmacieTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPanierBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'phar_vl_panier_title'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: _panier.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('phar_vl_panier_empty'.tr()),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _panier.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) {
                          return _panierLine(i, () {
                            setLocal(() {});
                            setState(() {});
                          });
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panierPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PharmacieTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_cart_outlined,
                  color: PharmacieTheme.primary),
              const SizedBox(width: 8),
              Text(
                'phar_vl_panier_title'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                '${_panier.length}',
                style: const TextStyle(
                  color: PharmacieTheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_panier.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'phar_vl_panier_empty'.tr(),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: PharmacieTheme.textMuted),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _panier.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _panierLine(i, () => setState(() {})),
              ),
            ),
          const Divider(),
          Row(
            children: [
              Text(
                'phar_total_label'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'phar_amount_fcfa'.tr(namedArgs: {
                  'amount': _total.toStringAsFixed(0),
                }),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: PharmacieTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _panier.isEmpty || _saving ? null : _valider,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text('phar_vl_validate'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmacieTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panierLine(int i, VoidCallback onChanged) {
    final p = _panier[i];
    final qte = p['quantite'] as int;
    final prix = p['prix_unitaire'] as double;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (p['nom_medicament'] ?? '').toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'phar_amount_fcfa'.tr(namedArgs: {
                    'amount': (prix * qte).toStringAsFixed(0),
                  }),
                  style: const TextStyle(
                    fontSize: 11,
                    color: PharmacieTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              _changerQte(i, -1);
              onChanged();
            },
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            color: PharmacieTheme.danger,
          ),
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              '$qte',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            onPressed: () {
              _changerQte(i, 1);
              onChanged();
            },
            icon: const Icon(Icons.add_circle_outline, size: 20),
            color: PharmacieTheme.success,
          ),
          IconButton(
            onPressed: () {
              _retirer(i);
              onChanged();
            },
            icon: const Icon(Icons.delete_outline, size: 20),
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}
