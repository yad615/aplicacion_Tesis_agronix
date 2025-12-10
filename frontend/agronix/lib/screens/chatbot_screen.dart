import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agronix/models/chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:agronix/models/calendar_event.dart';
import 'package:agronix/services/endpoints/chatbot_endpoints.dart';

class ChatBotScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ChatBotScreen({Key? key, this.userData}) : super(key: key);

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> with TickerProviderStateMixin {
    // Notificación de alertas automáticas
    void _showAlertasCreadasNotification(List<dynamic> alertas) {
      if (alertas.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Se generó una alerta automática'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Ver',
            textColor: Colors.white,
            onPressed: () => _showAlertasCreadasDialog(alertas),
          ),
        ),
      );
    }

    // Diálogo para mostrar alertas automáticas
    void _showAlertasCreadasDialog(List<dynamic> alertas) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('Alertas Automáticas', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Se generaron ${alertas.length} alertas automáticas:', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                ...alertas.map((alerta) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alerta is String ? alerta : (alerta['mensaje'] ?? 'Alerta automática'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar', style: TextStyle(color: Color(0xFF4A9B8E))),
            ),
          ],
        ),
      );
    }
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _isDisposed = false;
  bool _isInitialized = false;
  Map<String, dynamic>? _currentCropData;
  List<String> _tasksCreated = [];
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;
  SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  final FlutterTts _flutterTts = FlutterTts();
  File? _userImage;
  final ImagePicker _picker = ImagePicker();
  Future<void> _pickUserImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _userImage = File(pickedFile.path);
      });
      // Aquí podrías subir la imagen al backend si lo deseas
    }
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeChat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _analizarDatosDashboardYCrearTareas();
    });
  }

  void _analizarDatosDashboardYCrearTareas() {
    // Leer datos del dashboard
    final cropData = widget.userData != null ? widget.userData!["crop_data"] : null;
    List<String> tareasAuto = [];
    List<String> alertasAuto = [];
    if (cropData != null) {
      // Ejemplo: crear tarea si humedad suelo baja
      if (cropData["humidity_soil"] != null && cropData["humidity_soil"] < 35.0) {
        tareasAuto.add("Riego urgente por humedad baja");
        alertasAuto.add("💧 Humedad del suelo baja: ${cropData["humidity_soil"]}%");
      }
      if (cropData["temperature_air"] != null && cropData["temperature_air"] > 25.0) {
        tareasAuto.add("Ventilar invernadero por temperatura alta");
        alertasAuto.add("🔥 Temperatura del aire alta: ${cropData["temperature_air"]}°C");
      }
      if (cropData["pest_risk"] == "Alto") {
        tareasAuto.add("Inspección de plagas recomendada");
        alertasAuto.add("🐛 Riesgo de plagas alto");
      }
    }
    if (tareasAuto.isNotEmpty) {
      _addMessage("Se han creado automáticamente las siguientes tareas:", false);
      for (final t in tareasAuto) {
        _addMessage("• $t", false);
      }
      _addTasksToCalendar(tareasAuto);
      _showTasksCreatedNotification();
    }
    if (alertasAuto.isNotEmpty) {
      _showAlertasCreadasNotification(alertasAuto);
    }
  }

  Future<void> _initializeChat() async {
    if (_isInitialized) return;
    
    await _loadChatHistory();
    
    if (_messages.isEmpty) {
      _addInitialMessage();
    }
    
    _isInitialized = true;
  }

  void _setupAnimations() {
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _addInitialMessage() {
    final initialMessage = ChatMessage(
      message: '¡Hola! 👋 Soy **AgroNix**, tu asistente IA especializado en fresas.\n\n'
          '🌱 Puedo ayudarte con:\n'
          '• Análisis de datos de cultivo\n'
          '• Recomendaciones de riego y fertilización\n'
          '• Programación de tareas\n'
          '• Control de plagas\n\n'
          '💡 Desarrollado por *Yadhira Alcántara* y *Diego Sánchez*\n\n'
          '¿En qué puedo ayudarte hoy?',
      isUser: false,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(initialMessage);
    });
    
    _saveChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString('chat_history');
      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        final List<ChatMessage> loadedMessages = historyList
            .map((item) => ChatMessage.fromJson(item))
            .toList();
        
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(loadedMessages);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String historyJson = json.encode(_messages.map((msg) => msg.toJson()).toList());
      await prefs.setString('chat_history', historyJson);
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }

  Future<void> _clearChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_history');
      
      setState(() {
        _messages.clear();
      });
      
      _addInitialMessage();
    } catch (e) {
      debugPrint('Error clearing chat history: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _typingAnimationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage(String message, bool isUser) {
    if (_isDisposed) return;
    
    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          message: message,
          isUser: isUser,
          timestamp: DateTime.now(),
        ));
      });
      
      _saveChatHistory();
      _scrollToBottom();
      if (!isUser) {
        _speak(message);
      }
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage('es-ES');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.7); // Más lento
    // Filtra emojis y asteriscos antes de leer
    final cleanText = text
      .replaceAll(RegExp(r'[\*]+'), '')
      .replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}\u{2700}-\u{27BF}]', unicode: true), '');
    await _flutterTts.speak(cleanText);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && 
          _scrollController.hasClients && 
          _scrollController.position.hasContentDimensions) {
        try {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } catch (e) {
          debugPrint('Error scrolling: $e');
        }
      }
    });
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  // Helper: agrega tareas creadas automáticamente al calendario, marcando origen IA
  void _addTasksToCalendar(List<dynamic> tasks) {
    for (final task in tasks) {
      final event = CalendarEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: task is String ? task : (task['title'] ?? 'Tarea IA'),
        description: 'Tarea creada automáticamente por IA',
        dateTime: DateTime.now(),
        type: EventType.irrigation, // Mejorar si hay info
        priority: Priority.medium,
        origen: 'automatico',
      );
      CalendarEventBus().emit(event);
    }
  }

  Future<void> _sendMessage() async {
    _analizarDatosDashboardYCrearTareas();
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final username = widget.userData?['username'] ?? '';
    final parcelaId = widget.userData?['parcela_id'];
    _addMessage('$username: $text', true);
    _messageController.clear();

    _safeSetState(() {
      _isTyping = true;
    });
    _typingAnimationController.repeat();

    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    try {
      final response = await http.post(
        Uri.parse(ChatbotEndpoints.chat),
        headers: headers,
        body: json.encode({
          'message': text,
          'username': username,
          'parcela_id': parcelaId,
        }),
      );

      if (!_isDisposed && mounted) {
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final String botResponse = responseData['response'] as String? ?? 'Respuesta vacía';

          // Mostrar la respuesta tal cual, sin emojis ni modificaciones
          await Future.delayed(const Duration(milliseconds: 1800));
          _addMessage(botResponse, false);

          // Mostrar crop_data si viene
          if (responseData.containsKey('crop_data')) {
            _currentCropData = responseData['crop_data'];
          }

          // Notificar tareas automáticas
          if (responseData.containsKey('tasks_created') && responseData['tasks_created'] != null && (responseData['tasks_created'] as List).isNotEmpty) {
            _tasksCreated = List<String>.from(responseData['tasks_created']);
            _showTasksCreatedNotification();
            _addTasksToCalendar(_tasksCreated);
          }

          // Notificar alertas automáticas y emitirlas globalmente
          if (responseData.containsKey('acciones_creadas') && responseData['acciones_creadas'] != null && (responseData['acciones_creadas'] as List).isNotEmpty) {
            this._showAlertasCreadasNotification(responseData['acciones_creadas']);
          }
        } else {
          _handleApiError(response);
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        _addMessage('Error de conexión o el servidor no responde. Revisa tu internet, la IP y el backend.\nDetalles: $e', false);
        debugPrint('Network Error: $e');
      }
    } finally {
      _safeSetState(() {
        _isTyping = false;
      });
      _typingAnimationController.stop();
    }
  }

  void _handleApiError(http.Response response) {
    String errorMessage = '❌ Error del servidor (${response.statusCode})';
    try {
      final errorBody = json.decode(response.body);
      if (errorBody is Map<String, dynamic>) {
        if (errorBody['error'] != null && errorBody['error'].toString().isNotEmpty) {
          errorMessage = '❌ ${errorBody['error']}';
        } else if (errorBody['detail'] != null && errorBody['detail'].toString().isNotEmpty) {
          errorMessage = '❌ ${errorBody['detail']}';
        } else {
          errorMessage = '❌ ${response.body}';
        }
      } else {
        errorMessage = '❌ ${response.body}';
      }
    } catch (_) {
      errorMessage = '❌ ${response.body}';
    }
    _addMessage(errorMessage, false);
  }

  void _showTasksCreatedNotification() {
    if (_tasksCreated.isEmpty) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Se crearon ${_tasksCreated.length} tareas automáticamente'),
        backgroundColor: const Color(0xFF4A9B8E),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: _showTasksCreatedDialog,
        ),
      ),
    );
  }

  void _showTasksCreatedDialog() {
    if (_tasksCreated.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          '📋 Tareas Creadas',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Se crearon automáticamente ${_tasksCreated.length} tareas:',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              ..._tasksCreated.map((task) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•', style: TextStyle(color: Color(0xFF4A9B8E))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: Color(0xFF4A9B8E))),
          ),
        ],
      ),
    );
  }

  void _showCropDataDialog() {
    if (_currentCropData == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          '📊 Datos del Cultivo - Fresas "San Andreas"',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Última actualización:',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                _formatTimestamp(_currentCropData!['last_updated']),
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
              const SizedBox(height: 16),
              _buildDataRow('🌡️ Temperatura Aire', '${_currentCropData!['temperature_air']}°C', _getStatusColor('temperature_air')),
              _buildDataRow('💧 Humedad Aire', '${_currentCropData!['humidity_air']}%', _getStatusColor('humidity_air')),
              _buildDataRow('🌱 Humedad Suelo', '${_currentCropData!['humidity_soil']}%', _getStatusColor('humidity_soil')),
              _buildDataRow('⚡ Conductividad (EC)', '${_currentCropData!['conductivity_ec']} dS/m', _getStatusColor('conductivity_ec')),
              _buildDataRow('🌡️ Temperatura Suelo', '${_currentCropData!['temperature_soil']}°C', _getStatusColor('temperature_soil')),
              _buildDataRow('☀️ Radiación Solar', '${_currentCropData!['solar_radiation']} W/m²', _getStatusColor('solar_radiation')),
              _buildDataRow('🐛 Riesgo de Plagas', '${_currentCropData!['pest_risk']}', _getPestRiskColor()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: Color(0xFF4A9B8E))),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String parameter) {
    if (_currentCropData == null) return Colors.white;
    
    final value = _currentCropData![parameter];
    if (value == null) return Colors.white;
    
    final optimalRanges = {
      'temperature_air': {'min': 20.0, 'max': 25.0},
      'humidity_air': {'min': 60.0, 'max': 80.0},
      'humidity_soil': {'min': 35.0, 'max': 65.0},
      'conductivity_ec': {'min': 0.7, 'max': 1.2},
      'temperature_soil': {'min': 15.0, 'max': 25.0},
      'solar_radiation': {'min': 300.0, 'max': 800.0},
    };
    
    final range = optimalRanges[parameter];
    if (range == null) return Colors.white;
    
    if (value < range['min']! || value > range['max']!) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Color _getPestRiskColor() {
    if (_currentCropData == null) return Colors.white;
    
    final risk = _currentCropData!['pest_risk'];
    switch (risk) {
      case 'Bajo':
        return Colors.green;
      case 'Moderado':
        return Colors.orange;
      case 'Alto':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp is String) {
        final dateTime = DateTime.parse(timestamp);
        return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
      }
      return 'Fecha no disponible';
    } catch (e) {
      return 'Fecha no disponible';
    }
  }

  Widget _buildDataRow(String label, String value, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildMessageList(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A9B8E), Color(0xFF2D7A6B)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Row(
        children: [
            Stack(
              children: [
                _userImage != null
                    ? CircleAvatar(
                        radius: 24,
                        backgroundImage: FileImage(_userImage!),
                      )
                    : Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_circle, color: Colors.white, size: 32),
                      ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickUserImage,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A9B8E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AgroNix',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Asistente IA para Fresas',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_currentCropData != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: _showCropDataDialog,
                icon: const Icon(Icons.analytics, color: Colors.white),
                tooltip: 'Ver datos del cultivo',
              ),
            ),
          const SizedBox(width: 8),
          if (_tasksCreated.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: _showTasksCreatedDialog,
                icon: Stack(
                  children: [
                    const Icon(Icons.task_alt, color: Colors.white),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '${_tasksCreated.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                tooltip: 'Ver tareas creadas',
              ),
            ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF2A2A2A),
                    title: const Text(
                      '🗑️ Limpiar Chat',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      '¿Estás seguro de que deseas limpiar el historial de chat?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearChatHistory();
                        },
                        child: const Text('Limpiar', style: TextStyle(color: Color(0xFF4A9B8E))),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: 'Limpiar chat',
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length + (_isTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length && _isTyping) {
            return _buildTypingIndicator();
          }
          
          if (index >= 0 && index < _messages.length) {
            final message = _messages[index];
            return _buildMessageBubble(message);
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'AgroNix está analizando',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Row(
                  children: List.generate(3, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white70.withOpacity(
                          ((_typingAnimation.value + index * 0.3) % 1.0).clamp(0.2, 1.0),
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          gradient: message.isUser 
            ? const LinearGradient(
                colors: [Color(0xFF4A9B8E), Color(0xFF2D7A6B)],
              )
            : null,
          color: message.isUser ? null : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: message.message,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
                strong: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                em: const TextStyle(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
                listBullet: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startListening() async {
    // Primero verificar el estado actual del permiso
    var permissionStatus = await Permission.microphone.status;
    
    if (permissionStatus.isDenied) {
      // Si está denegado, pedirlo
      permissionStatus = await Permission.microphone.request();
    }
    
    if (permissionStatus.isGranted) {
      // Permiso concedido, inicializar speech-to-text
      bool available = await _speechToText.initialize(
        onError: (error) {
          print('Error en speech: $error');
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error.errorMsg}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        onStatus: (status) {
          print('Estado del speech: $status');
        },
      );
      
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (result) {
            if (result.finalResult) {
              setState(() {
                _messageController.text = result.recognizedWords;
                _isListening = false;
              });
            }
          },
          localeId: 'es_ES',
          listenMode: ListenMode.confirmation,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El reconocimiento de voz no está disponible en este dispositivo.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else if (permissionStatus.isPermanentlyDenied) {
      // Denegado permanentemente, debe ir a ajustes
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('Permiso Requerido', style: TextStyle(color: Colors.white)),
          content: const Text(
            'El permiso del micrófono está denegado permanentemente. '
            'Para usar la función de voz, debes habilitarlo manualmente en los ajustes de la aplicación.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A9B8E)),
              child: const Text('Abrir Ajustes', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else if (permissionStatus.isRestricted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El acceso al micrófono está restringido en este dispositivo.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // Permiso denegado esta vez
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Permiso de micrófono denegado. Por favor, concede el permiso para usar esta función.'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: () => _startListening(),
          ),
        ),
      );
    }
  }

  void _stopListening() {
    _speechToText.stop();
    setState(() => _isListening = false);
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFF4A9B8E), width: 0.5),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF2A2A2A), // Fondo oscuro
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: Color(0xFF4A9B8E)), // Borde verde
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: Color(0xFF4A9B8E)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: Color(0xFF4A9B8E), width: 2),
                  ),
                  hintText: 'Pregunta sobre tus fresas...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A9B8E), Color(0xFF2D7A6B)],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isListening
                      ? [Colors.red, Colors.orange]
                      : [Color(0xFF4A9B8E), Color(0xFF2D7A6B)],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                _isListening ? Icons.mic_off : Icons.mic,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
