// lib/screens/parcelas_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:agronix/services/api_service.dart'; // Asegúrate que la ruta a tu servicio API sea correcta

class ParcelasScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ParcelasScreen({super.key, required this.userData});

  @override
  State<ParcelasScreen> createState() => _ParcelasScreenState();
}

class _ParcelasScreenState extends State<ParcelasScreen> with TickerProviderStateMixin {
  // --- ESTADO Y ANIMACIONES ---
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  List<Map<String, dynamic>> _parcelas = [];
  bool _isLoading = true;

  // ✅ CAMBIO: Estados para manejar la lista de planes
  List<dynamic> _plans = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    _loadInitialData(); // Carga tanto parcelas como planes al iniciar
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE API ---

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    // Ejecuta ambas cargas de datos en paralelo para mayor eficiencia
    await Future.wait([
      _loadParcelas(),
      _loadPlans(),
    ]);

    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _loadParcelas() async {
    final String? userToken = widget.userData['token'];
    if (userToken == null) return;

    try {
      final responseData = await ApiService.getParcelas(userToken);
      if (!mounted) return;
      
      final parcelasList = responseData['results'] as List;
      setState(() {
        _parcelas = List<Map<String, dynamic>>.from(parcelasList);
      });
    } catch (e) {
      print('Excepción al cargar parcelas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar las parcelas.'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  // ✅ CAMBIO: Nueva función para cargar los planes disponibles
  Future<void> _loadPlans() async {
    final String? userToken = widget.userData['token'];
    if (userToken == null) return;

    try {
      final plansData = await ApiService.getPlans(userToken);
      if (!mounted) return;
      setState(() {
        _plans = plansData;
      });
    } catch (e) {
      print('Excepción al cargar planes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar los planes disponibles.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _createParcela(Map<String, dynamic> parcelaData) async {
    final String? userToken = widget.userData['token'];
    if (userToken == null) return;
    
    // Validación para asegurar que se envíe un plan
    if (parcelaData['plan_id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Debes seleccionar un plan.'), backgroundColor: Colors.orange),
        );
        return;
    }

    try {
      await ApiService.createParcela(userToken, parcelaData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parcela creada exitosamente.'), backgroundColor: Colors.green),
      );
      await _loadParcelas(); // Recarga la lista de parcelas tras la creación
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear la parcela: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteParcela(int id) async {
    final String? userToken = widget.userData['token'];
    if (userToken == null) return;

    try {
      await ApiService.deleteParcela(userToken, id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parcela eliminada exitosamente.'), backgroundColor: Colors.red),
      );
      await _loadParcelas(); // Recarga la lista tras eliminar
    } catch(e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar la parcela.'), backgroundColor: Colors.red),
      );
    }
  }

  // --- ANIMACIONES ---

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
  }

  void _startAnimations() {
    _animationController.forward();
  }

  // --- WIDGETS DE UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Mis Parcelas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadInitialData,
            tooltip: 'Refrescar',
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9B8E))))
                : const Icon(Icons.refresh, color: Color(0xFF4A9B8E)),
          ),
          IconButton(
            onPressed: _showAddParcelaDialog,
            tooltip: 'Añadir Parcela',
            icon: const Icon(Icons.add, color: Color(0xFF4A9B8E)),
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingView() : _buildParcelasContent(),
    );
  }

  // ✅ CAMBIO: Diálogo de creación completamente renovado para incluir el selector de planes y validación.
  void _showAddParcelaDialog() {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final areaController = TextEditingController();
    final ubicacionController = TextEditingController();
    int? selectedPlanId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Nueva Parcela', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Nombre de la Parcela'),
                        validator: (value) => value == null || value.isEmpty ? 'El nombre es obligatorio.' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: areaController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Tamaño (hectáreas)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: ubicacionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Ubicación (Opcional)'),
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<int>(
                        value: selectedPlanId,
                        hint: const Text('Selecciona un plan', style: TextStyle(color: Colors.grey)),
                        isExpanded: true,
                        decoration: _inputDecoration('Plan de Suscripción'),
                        dropdownColor: const Color(0xFF333333),
                        style: const TextStyle(color: Colors.white),
                        items: _plans.map<DropdownMenuItem<int>>((plan) {
                          return DropdownMenuItem<int>(
                            value: plan['id'],
                            child: Text(plan['nombre'] ?? 'Plan sin nombre'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedPlanId = value;
                          });
                        },
                        validator: (value) => value == null ? 'Debes seleccionar un plan.' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: TextStyle(color: Colors.grey[400]))),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final data = {
                        'nombre': nombreController.text,
                        'tamano_hectareas': areaController.text.isNotEmpty ? double.tryParse(areaController.text) : null,
                        'ubicacion': ubicacionController.text,
                        'plan_id': selectedPlanId, // <-- Se añade el ID del plan seleccionado
                      };
                      Navigator.pop(context);
                      _createParcela(data);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A9B8E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text('Crear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showParcelaDetails(Map<String, dynamic> parcela) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(parcela['nombre'] ?? 'Detalles', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Plan Activo:', parcela['plan_activo'] ?? 'No especificado'),
            _buildDetailRow('Ubicación:', parcela['ubicacion']?.isNotEmpty == true ? parcela['ubicacion'] : 'No especificada'),
            _buildDetailRow('Tamaño:', '${parcela['tamano_hectareas'] ?? 'N/A'} hectáreas'),
            _buildDetailRow('Creada el:', DateFormat('dd/MM/yyyy').format(DateTime.parse(parcela['created_at']))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation(parcela);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A9B8E)),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> parcela) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar Eliminación', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        content: Text('¿Deseas eliminar permanentemente la parcela "${parcela['nombre']}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: TextStyle(color: Colors.grey[400]))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteParcela(parcela['id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9B8E))),
          SizedBox(height: 16),
          Text('Cargando datos...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildParcelasContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Column(
              children: [
                _buildSummarySection(),
                Expanded(child: _buildParcelasList()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummarySection() {
    final totalArea = _parcelas.fold<double>(0.0, (sum, p) {
      final size = p['tamano_hectareas'];
      return sum + (size != null ? (double.tryParse(size.toString()) ?? 0.0) : 0.0);
    });
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('${_parcelas.length}', 'Parcelas'),
          _buildSummaryDivider(),
          _buildSummaryItem('${totalArea.toStringAsFixed(1)}', 'Hectáreas'),
        ],
      ),
    );
  }

  Widget _buildParcelasList() {
    if (_parcelas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.landscape_outlined, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text('No tienes parcelas registradas', style: TextStyle(color: Colors.grey[400], fontSize: 18)),
            const SizedBox(height: 8),
            Text('Toca el botón + para crear tu primera parcela', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _parcelas.length,
      itemBuilder: (context, index) {
        final parcela = _parcelas[index];
        return _buildParcelaCard(parcela);
      },
    );
  }

  Widget _buildParcelaCard(Map<String, dynamic> parcela) {
    final planName = parcela['plan_activo'] ?? 'Sin plan asignado';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showParcelaDetails(parcela),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4A9B8E).withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A9B8E).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.eco, color: Color(0xFF4A9B8E), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parcela['nombre'] ?? 'Sin Nombre', 
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)
                      ),
                      const SizedBox(height: 4),
                      Text(
                        planName,
                        style: const TextStyle(color: Color(0xFF4A9B8E), fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Color(0xFF4A9B8E), fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSummaryDivider() {
    return Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3));
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[400]),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[600]!)),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4A9B8E))),
      errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent, width: 2.0)),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}