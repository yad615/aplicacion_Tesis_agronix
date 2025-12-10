// lib/screens/parcelas_screen.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:agronix/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:agronix/services/endpoints/parcela_endpoints.dart';
import 'package:agronix/config/api_config.dart';

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

  // Los planes se obtienen directamente desde cada parcela (plan-activo endpoint)

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

    // Solo carga las parcelas (cada parcela ya incluye su plan activo)
    await _loadParcelas();

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
          const SnackBar(content: Text('No se pudo cargar las parcelas. Verifica tu conexión o vuelve a intentar.'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  // Los planes activos se obtienen automáticamente desde /api/parcelas/{id}/plan-activo/
  // No es necesario cargar una lista genérica de planes

  Future<void> _createParcela(Map<String, dynamic> parcelaData, {File? imageFile}) async {
    final String? userToken = widget.userData['token'];
    if (userToken == null) return;

    try {
      // Crear multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ParcelaEndpoints.create),
      );

      // Headers
      request.headers['Authorization'] = 'Token $userToken';

      // Campos de texto
      request.fields['nombre'] = parcelaData['nombre'];
      
      if (parcelaData['tamano_hectareas'] != null) {
        request.fields['tamano_hectareas'] = parcelaData['tamano_hectareas'].toString();
      }
      
      if (parcelaData['ubicacion'] != null && parcelaData['ubicacion'].toString().isNotEmpty) {
        request.fields['ubicacion'] = parcelaData['ubicacion'];
      }

      // Agregar campos de ciclo si existen
      if (parcelaData['ciclo'] != null) {
        final ciclo = parcelaData['ciclo'];
        if (ciclo['cultivo'] != null) {
          request.fields['cultivo'] = ciclo['cultivo'].toString();
        }
        if (ciclo['variedad'] != null) {
          request.fields['variedad'] = ciclo['variedad'].toString();
        }
        if (ciclo['etapa_actual'] != null) {
          request.fields['etapa_actual'] = ciclo['etapa_actual'].toString();
        }
        if (ciclo['etapa_inicio'] != null) {
          request.fields['etapa_inicio'] = ciclo['etapa_inicio'].toString();
        }
      }

      // Agregar imagen si existe
      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'imagen',
          imageFile.path,
        ));
      }

      // Enviar request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La parcela se creó correctamente.'), backgroundColor: Colors.green),
        );
        await _loadParcelas();
      } else if (response.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos inválidos. Verifica los campos.'), backgroundColor: Colors.orange),
        );
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No autorizado. Inicia sesión nuevamente.'), backgroundColor: Colors.red),
        );
      } else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tienes permisos para crear parcelas.'), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error del servidor (${response.statusCode}).'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteParcela(int id) async {
    final String? userToken = widget.userData['token'];
    if (userToken == null) return;

    try {
      final response = await http.delete(
        Uri.parse(ParcelaEndpoints.delete(id)),
        headers: {'Authorization': 'Token $userToken'},
      );

      if (!mounted) return;

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La parcela fue eliminada.'), backgroundColor: Colors.green),
        );
        await _loadParcelas();
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token inválido. Inicia sesión nuevamente.'), backgroundColor: Colors.red),
        );
      } else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No puedes eliminar esta parcela.'), backgroundColor: Colors.red),
        );
      } else if (response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parcela no encontrada.'), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error del servidor (${response.statusCode}).'), backgroundColor: Colors.red),
        );
      }
    } catch(e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Método para actualizar parcela completa (PUT)
  Future<void> _updateParcela(int id, Map<String, dynamic> parcelaData, {File? imageFile}) async {
    final String? userToken = widget.userData['token'];
    if (userToken == null) return;

    if (parcelaData['plan_id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un plan para continuar.'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      var request = http.MultipartRequest('PUT', Uri.parse(ParcelaEndpoints.update(id)));
      request.headers['Authorization'] = 'Token $userToken';

      request.fields['nombre'] = parcelaData['nombre'];
      request.fields['plan_id'] = parcelaData['plan_id'].toString();
      
      if (parcelaData['tamano_hectareas'] != null) {
        request.fields['tamano_hectareas'] = parcelaData['tamano_hectareas'].toString();
      }
      
      if (parcelaData['ubicacion'] != null && parcelaData['ubicacion'].toString().isNotEmpty) {
        request.fields['ubicacion'] = parcelaData['ubicacion'];
      }

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('imagen', imageFile.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parcela actualizada correctamente.'), backgroundColor: Colors.green),
        );
        await _loadParcelas();
      } else if (response.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos inválidos.'), backgroundColor: Colors.orange),
        );
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No autorizado.'), backgroundColor: Colors.red),
        );
      } else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No puedes editar esta parcela.'), backgroundColor: Colors.red),
        );
      } else if (response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parcela no encontrada.'), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error (${response.statusCode}).'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Método para actualizar parcialmente (PATCH)
  Future<void> _patchParcela(int id, Map<String, dynamic> parcelaData, {File? imageFile}) async {
    final String? userToken = widget.userData['token'];
    if (userToken == null) return;

    try {
      var request = http.MultipartRequest('PATCH', Uri.parse(ParcelaEndpoints.update(id)));
      request.headers['Authorization'] = 'Token $userToken';

      // Solo agregar campos que no sean null
      if (parcelaData['nombre'] != null) {
        request.fields['nombre'] = parcelaData['nombre'];
      }
      
      if (parcelaData['plan_id'] != null) {
        request.fields['plan_id'] = parcelaData['plan_id'].toString();
      }
      
      if (parcelaData['tamano_hectareas'] != null) {
        request.fields['tamano_hectareas'] = parcelaData['tamano_hectareas'].toString();
      }
      
      if (parcelaData['ubicacion'] != null) {
        request.fields['ubicacion'] = parcelaData['ubicacion'];
      }

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('imagen', imageFile.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parcela actualizada.'), backgroundColor: Colors.green),
        );
        await _loadParcelas();
      } else if (response.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos inválidos.'), backgroundColor: Colors.orange),
        );
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No autorizado.'), backgroundColor: Colors.red),
        );
      } else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sin permisos.'), backgroundColor: Colors.red),
        );
      } else if (response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parcela no encontrada.'), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error (${response.statusCode}).'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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

  // ✅ CAMBIO: Diálogo de creación completamente renovado para incluir el selector de planes, imagen y validación.
  void _showAddParcelaDialog() {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final ubicacionController = TextEditingController();
    final areaController = TextEditingController();
    final latitudController = TextEditingController();
    final longitudController = TextEditingController();
    final altitudController = TextEditingController();
    final etapaInicioController = TextEditingController();
    File? selectedImage;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A9B8E).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_location_alt, color: Color(0xFF4A9B8E), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text('Nueva Parcela', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
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
                      // Etapa de inicio calendar (debajo del nombre)
                      GestureDetector(
                        onTap: () async {
                          FocusScope.of(context).unfocus();
                          showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              DateTime _focusedDay = DateTime.now();
                              DateTime _selectedDay = DateTime.now();
                              return StatefulBuilder(
                                builder: (context, setModalState) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    child: TableCalendar(
                                      locale: 'es_ES',
                                      firstDay: DateTime.utc(2000, 1, 1),
                                      lastDay: DateTime.utc(2100, 12, 31),
                                      focusedDay: _focusedDay,
                                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                                      onDaySelected: (selectedDay, focusedDay) {
                                        setModalState(() {
                                          _selectedDay = selectedDay;
                                          _focusedDay = focusedDay;
                                        });
                                        setDialogState(() {
                                          etapaInicioController.text = selectedDay.toIso8601String().substring(0, 10);
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: etapaInicioController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Etapa de inicio (fecha)'),
                            validator: (value) => value == null || value.isEmpty ? 'Selecciona una fecha.' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: ubicacionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Ubicación'),
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
                        controller: latitudController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Latitud'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: longitudController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Longitud'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: altitudController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Altitud (m)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      ),
                      const SizedBox(height: 24),
                      // INFO: Los planes se asignan desde el backend/admin
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Color(0xFF4A9B8E).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFF4A9B8E).withOpacity(0.18)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFF4A9B8E), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Los planes se asignan automáticamente desde el sistema.',
                                style: const TextStyle(color: Color(0xFF4A9B8E), fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Selector de imagen con logging de errores
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1920,
                              maxHeight: 1920,
                              imageQuality: 85,
                            );
                            if (image != null) {
                              final ext = image.path.split('.').last.toLowerCase();
                              if (!['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('El archivo seleccionado no es una imagen válida.'), backgroundColor: Colors.red),
                                );
                                return;
                              }
                              print('📸 Imagen seleccionada: ${image.path}');
                              final imageFile = File(image.path);
                              final exists = await imageFile.exists();
                              if (!exists) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('No se pudo acceder al archivo de imagen.'), backgroundColor: Colors.red),
                                );
                                return;
                              }
                              print('📁 Archivo existe: $exists, Tamaño: ${await imageFile.length()} bytes');
                              setDialogState(() {
                                selectedImage = imageFile;
                              });
                            }
                          } catch (e, st) {
                            print('❌ Error al seleccionar imagen: $e');
                            print('StackTrace: $st');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al seleccionar imagen: $e'), backgroundColor: Colors.red),
                            );
                          }
                        },
                        icon: Icon(
                          selectedImage == null ? Icons.add_photo_alternate : Icons.check_circle,
                          color: selectedImage == null ? Colors.white70 : const Color(0xFF4A9B8E),
                        ),
                        label: Text(
                          selectedImage == null ? 'Seleccionar Imagen (Opcional)' : 'Imagen seleccionada',
                          style: TextStyle(
                            color: selectedImage == null ? Colors.white70 : const Color(0xFF4A9B8E),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: selectedImage == null ? Colors.white38 : const Color(0xFF4A9B8E),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      if (selectedImage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => _FullScreenImage(imageFile: selectedImage!),
                                ),
                              );
                            },
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF4A9B8E), width: 2),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: SizedBox(
                                      height: 120,
                                      child: Builder(
                                        builder: (context) {
                                          try {
                                            return Image.file(
                                              selectedImage!,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                print('❌ Error al cargar imagen local: $error');
                                                print('StackTrace: $stackTrace');
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF2A2A2A),
                                                    borderRadius: BorderRadius.circular(14),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.broken_image_outlined, color: Colors.red, size: 40),
                                                      SizedBox(height: 8),
                                                      Text('Error al cargar', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 4.0),
                                                        child: Text(
                                                          error.toString(),
                                                          style: TextStyle(color: Colors.redAccent, fontSize: 10),
                                                          textAlign: TextAlign.center,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                                if (wasSynchronouslyLoaded) return child;
                                                return frame != null
                                                    ? child
                                                    : Container(
                                                        color: const Color(0xFF2A2A2A),
                                                        child: const Center(
                                                          child: CircularProgressIndicator(color: Color(0xFF4A9B8E)),
                                                        ),
                                                      );
                                              },
                                            );
                                          } catch (e, st) {
                                            print('❌ Error crítico al renderizar imagen: $e');
                                            print('StackTrace: $st');
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2A2A2A),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.broken_image_outlined, color: Colors.red, size: 40),
                                                  SizedBox(height: 8),
                                                  Text('Error crítico al renderizar', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 4.0),
                                                    child: Text(
                                                      e.toString(),
                                                      style: TextStyle(color: Colors.redAccent, fontSize: 10),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                          SizedBox(width: 4),
                                          Text('Toca para ampliar', style: TextStyle(color: Colors.white, fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                        'ubicacion': ubicacionController.text,
                        'tamano_hectareas': areaController.text.isNotEmpty ? double.tryParse(areaController.text) : null,
                        'latitud': latitudController.text.isNotEmpty ? double.tryParse(latitudController.text) : null,
                        'longitud': longitudController.text.isNotEmpty ? double.tryParse(longitudController.text) : null,
                        'altitud': altitudController.text.isNotEmpty ? double.tryParse(altitudController.text) : null,
                        'etapa_inicio': etapaInicioController.text,
                        // 'imagen_url' se maneja desde el backend al subir la imagen
                      };
                      Navigator.pop(context);
                      _createParcela(data, imageFile: selectedImage);
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

  // Diálogo para editar parcela existente
  void _showEditParcelaDialog(Map<String, dynamic> parcela) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: parcela['nombre']);
    final areaController = TextEditingController(text: parcela['tamano_hectareas']?.toString() ?? '');
    final ubicacionController = TextEditingController(text: parcela['ubicacion'] ?? '');
    int? selectedPlanId = parcela['plan_id'];
    File? selectedImage;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Editar Parcela', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mostrar imagen actual si existe
                      if (parcela['imagen_url'] != null && selectedImage == null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            children: [
                              const Text('Imagen Actual:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  parcela['imagen_url'],
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 100,
                                      color: Colors.grey[800],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                              : null,
                                          color: const Color(0xFF4A9B8E),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error cargando imagen de red: $error');
                                    return Container(
                                      height: 100,
                                      color: Colors.grey[800],
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image, color: Colors.white38, size: 40),
                                          SizedBox(height: 4),
                                          Text('No se pudo cargar', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
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
                      // INFO: Los planes no se pueden cambiar desde aquí
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Para cambiar el plan, contacta al administrador.',
                                style: const TextStyle(color: Colors.blue, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Selector de nueva imagen
                      OutlinedButton.icon(
                        onPressed: () async {
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 1920,
                            maxHeight: 1920,
                            imageQuality: 85,
                          );
                          if (image != null) {
                            print('📸 Imagen seleccionada (editar): ${image.path}');
                            final imageFile = File(image.path);
                            final exists = await imageFile.exists();
                            print('📁 Archivo existe: $exists, Tamaño: ${exists ? await imageFile.length() : 0} bytes');
                            
                            setDialogState(() {
                              selectedImage = imageFile;
                            });
                          }
                        },
                        icon: Icon(
                          selectedImage == null ? Icons.add_photo_alternate : Icons.check_circle,
                          color: selectedImage == null ? Colors.white70 : const Color(0xFF4A9B8E),
                        ),
                        label: Text(
                          selectedImage == null ? 'Cambiar Imagen (Opcional)' : 'Nueva imagen seleccionada',
                          style: TextStyle(
                            color: selectedImage == null ? Colors.white70 : const Color(0xFF4A9B8E),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: selectedImage == null ? Colors.white38 : const Color(0xFF4A9B8E),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      if (selectedImage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => _FullScreenImage(imageFile: selectedImage!),
                                ),
                              );
                            },
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF4A9B8E), width: 2),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(
                                      selectedImage!,
                                      width: double.infinity,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2A2A2A),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.broken_image_outlined, color: Colors.red, size: 40),
                                              SizedBox(height: 8),
                                              Text('Error al cargar', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                            ],
                                          ),
                                        );
                                      },
                                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                        if (wasSynchronouslyLoaded) return child;
                                        return frame != null
                                            ? child
                                            : Container(
                                                color: const Color(0xFF2A2A2A),
                                                child: const Center(
                                                  child: CircularProgressIndicator(color: Color(0xFF4A9B8E)),
                                                ),
                                              );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                          SizedBox(width: 4),
                                          Text('Toca para ampliar', style: TextStyle(color: Colors.white, fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                        'plan_id': selectedPlanId,
                      };
                      Navigator.pop(context);
                      _updateParcela(parcela['id'], data, imageFile: selectedImage);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A9B8E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showParcelaDetails(Map<String, dynamic> parcela) async {
      // Estado para galería
      List<dynamic> imagenesParcela = [];
      bool cargandoImagenes = false;
    // Mostrar loading mientras carga el plan
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9B8E))
        )
      ),
    );

    // Obtener plan activo de la parcela
    Map<String, dynamic>? planData;
    try {
      final String? userToken = widget.userData['token'];
      if (userToken != null) {
        planData = await ApiService.getPlanActivo(userToken, parcela['id']);
      }
    } catch (e) {
      print('Error al cargar plan activo: $e');
    }

    if (!mounted) return;
    Navigator.pop(context); // Cerrar loading

    // Mostrar diálogo con detalles
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)
          ),
          title: Row(
            children: [
              Icon(Icons.landscape, color: Color(0xFF4A9B8E)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  parcela['nombre'] ?? 'Detalles',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600
                  )
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información básica de la parcela
                _buildDetailRow('Ubicación:',
                  (parcela['ubicacion'] != null && parcela['ubicacion'].toString().isNotEmpty)
                    ? parcela['ubicacion'].toString()
                    : 'No especificada'
                ),
                _buildDetailRow('Tamaño:',
                  '${parcela['tamano_hectareas'] ?? 'N/A'} hectáreas'
                ),
                _buildDetailRow('Creada el:',
                  parcela['created_at'] != null
                    ? DateFormat('dd/MM/yyyy').format(DateTime.parse(parcela['created_at']))
                    : 'Fecha no disponible'
                ),
                SizedBox(height: 16),
                Divider(color: Colors.grey[700]),
                SizedBox(height: 16),

                // Sección de ciclo activo (cultivo, variedad, etapa)
                if (parcela['ciclo_activo'] != null) ...[
                  Divider(color: Colors.grey[700]),
                  SizedBox(height: 12),
                  Text('Ciclo activo', style: TextStyle(color: Color(0xFF4A9B8E), fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  _buildDetailRow('Cultivo:',
                    parcela['ciclo_activo']['cultivo']?['nombre'] ?? 'No especificado'),
                  _buildDetailRow('Variedad:',
                    parcela['ciclo_activo']['variedad']?['nombre'] ?? 'No especificada'),
                  _buildDetailRow('Etapa actual:',
                    parcela['ciclo_activo']['etapa_actual']?['nombre'] ?? 'No especificada'),
                  _buildDetailRow('Estado:',
                    parcela['ciclo_activo']['estado'] ?? 'No especificado'),
                  _buildDetailRow('Inicio ciclo:',
                    parcela['ciclo_activo']['etapa_inicio'] ?? parcela['etapa_inicio'] ?? 'No especificado'),
                  SizedBox(height: 16),
                ],
                // Sección de plan activo
                if (planData != null && planData['tiene_plan'] == true)
                  _buildPlanSection(planData['suscripcion'])
                else
                  _buildNoPlanSection(),

                SizedBox(height: 20),
                // Botón para ver galería de imágenes
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A9B8E),
                  ),
                  icon: Icon(Icons.photo_library),
                  label: Text('Ver galería de imágenes'),
                  onPressed: cargandoImagenes
                      ? null
                      : () async {
                          setState(() { cargandoImagenes = true; });
                          try {
                            final String? userToken = widget.userData['token'];
                            if (userToken != null) {
                              // Usar la misma lógica que la preview de parcela para obtener imágenes
                              final previewImages = await ApiService.getParcelaImages(userToken, parcela['id']);
                              imagenesParcela = previewImages;
                            }
                          } catch (e, st) {
                            print('❌ Error al cargar imágenes de galería: $e');
                            print('StackTrace: $st');
                            imagenesParcela = [];
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al cargar galería: $e'), backgroundColor: Colors.red),
                            );
                          }
                          setState(() { cargandoImagenes = false; });
                          if (!mounted) return;
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF232323),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Text('Galería de Imágenes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              content: imagenesParcela.isEmpty
                                  ? Text('No hay imágenes para esta parcela.', style: TextStyle(color: Colors.white70))
                                  : SizedBox(
                                      width: 320,
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                        ),
                                        itemCount: imagenesParcela.length,
                                        itemBuilder: (context, idx) {
                                          final img = imagenesParcela[idx];
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.network(
                                              img['image_url'],
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                print('❌ Error al cargar imagen de galería: $error');
                                                print('StackTrace: $stackTrace');
                                                return Container(
                                                  color: Colors.grey[800],
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.broken_image, color: Colors.grey, size: 32),
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 4.0),
                                                        child: Text(
                                                          error.toString(),
                                                          style: TextStyle(color: Colors.redAccent, fontSize: 10),
                                                          textAlign: TextAlign.center,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cerrar', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showDeleteConfirmation(parcela);
              },
              child: Text('Eliminar',
                style: TextStyle(color: Colors.redAccent)
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4A9B8E)
              ),
              child: Text('Cerrar',
                style: TextStyle(color: Colors.white)
              ),
            )
          ],
        ),
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
            Icon(Icons.landscape_outlined, size: 64, color: Color(0xFF4A9B8E)),
            const SizedBox(height: 16),
            Text('No hay parcelas registradas.', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Presiona el botón "Añadir Parcela" para crear una.', style: TextStyle(color: Colors.white70, fontSize: 14)),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4A9B8E).withOpacity(0.3), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen de la parcela
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: parcela['imagen_url'] != null && parcela['imagen_url'].toString().isNotEmpty
                      ? Image.network(
                          parcela['imagen_url'],
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 64,
                            height: 64,
                            color: Colors.grey[800],
                            child: const Icon(Icons.broken_image, color: Colors.grey, size: 32),
                          ),
                        )
                      : Container(
                          width: 64,
                          height: 64,
                          color: Colors.grey[900],
                          child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 32),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parcela['nombre'] ?? 'Sin Nombre',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (planName != 'Sin plan asignado')
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(0xFF4A9B8E),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                planName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Sin Plan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          SizedBox(width: 8),
                          Text(
                            '${parcela['tamano_hectareas'] ?? 'N/A'} ha',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13
                            ),
                          ),
                        ],
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
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF4A9B8E), width: 2),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent, width: 2.0),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
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

  Widget _buildPlanSection(Map<String, dynamic> suscripcion) {
    final plan = suscripcion['plan'];
    final diasRestantes = suscripcion['dias_restantes'] ?? 0;
    final proximaRenovacion = suscripcion['proxima_renovacion'];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFF4A9B8E).withOpacity(0.3),
          width: 1
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: Color(0xFF4A9B8E), size: 20),
              SizedBox(width: 8),
              Text(
                'Plan Activo',
                style: TextStyle(
                  color: Color(0xFF4A9B8E),
                  fontSize: 16,
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            plan['nombre'] ?? 'Sin nombre',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold
            ),
          ),
          SizedBox(height: 4),
          Text(
            '\$${plan['precio_mensual']}/mes',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14
            ),
          ),
          SizedBox(height: 12),
          Divider(color: Colors.grey[800]),
          SizedBox(height: 8),
          _buildInfoRow(
            Icons.calendar_today,
            'Lecturas diarias:',
            '${plan['veces_por_dia']} veces'
          ),
          SizedBox(height: 8),
          _buildInfoRow(
            Icons.schedule,
            'Días restantes:',
            '$diasRestantes días'
          ),
          SizedBox(height: 8),
          _buildInfoRow(
            Icons.refresh,
            'Próxima renovación:',
            proximaRenovacion != null
              ? DateFormat('dd/MM/yyyy').format(
                  DateTime.parse(proximaRenovacion)
                )
              : 'N/A'
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Función "Cambiar Plan" próximamente'),
                        backgroundColor: Colors.orange
                      )
                    );
                  },
                  icon: Icon(Icons.swap_horiz, size: 18),
                  label: Text('Cambiar Plan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF4A9B8E),
                    side: BorderSide(color: Color(0xFF4A9B8E)),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Función "Cancelar" próximamente'),
                        backgroundColor: Colors.orange
                      )
                    );
                  },
                  icon: Icon(Icons.cancel, size: 18),
                  label: Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(color: Colors.redAccent),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoPlanSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange, size: 48),
          SizedBox(height: 12),
          Text(
            'Sin Plan Activo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Esta parcela no tiene un plan de suscripción activo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Función "Ver Planes" próximamente'),
                  backgroundColor: Colors.orange
                )
              );
            },
            icon: Icon(Icons.add_shopping_cart),
            label: Text('Ver Planes Disponibles'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF4A9B8E), size: 16),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// Widget para mostrar imagen en pantalla completa
class _FullScreenImage extends StatelessWidget {
  final File imageFile;

  const _FullScreenImage({required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Imagen de Parcela', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            imageFile,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image_outlined, color: Colors.red, size: 80),
                  SizedBox(height: 20),
                  Text(
                    'Error al cargar la imagen',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}