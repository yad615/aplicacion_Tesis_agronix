import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agronix/models/chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatBotScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ChatBotScreen({Key? key, this.userData}) : super(key: key);

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> with TickerProviderStateMixin {
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

  final String _djangoBaseUrl = 'http://10.0.2.2:8000';
  final String _chatbotEndpoint = '/api/chat/';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeChat();
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
      print('Error loading chat history: $e');
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String historyJson = json.encode(_messages.map((msg) => msg.toJson()).toList());
      await prefs.setString('chat_history', historyJson);
    } catch (e) {
      print('Error saving chat history: $e');
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
      print('Error clearing chat history: $e');
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
    }
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
          print('Error scrolling: $e');
        }
      }
    });
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _addMessage(text, true);
    _messageController.clear();

    _safeSetState(() {
      _isTyping = true;
    });
    _typingAnimationController.repeat();

    final String? userToken = widget.userData?['token'] as String?;
    final int? userId = widget.userData?['id'] as int?;
    
    if (userToken == null || userToken.isEmpty) {
      _addMessage('❌ Error de autenticación. Por favor, inicia sesión nuevamente.', false);
      _safeSetState(() {
        _isTyping = false;
      });
      _typingAnimationController.stop();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_djangoBaseUrl$_chatbotEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: json.encode({
          'message': text,
        }),
      );

      if (!_isDisposed && mounted) {
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final String botResponse = responseData['response'] as String? ?? 'Respuesta vacía';
          
          if (responseData.containsKey('crop_data')) {
            _currentCropData = responseData['crop_data'];
          }
          
          if (responseData.containsKey('tasks_created')) {
            _tasksCreated = List<String>.from(responseData['tasks_created'] ?? []);
          }
          
          _addMessage(botResponse, false);
          
          if (_tasksCreated.isNotEmpty) {
            _showTasksCreatedNotification();
          }
        } else {
          _handleApiError(response);
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        _addMessage('🔌 Error de conexión. Revisa tu internet e intenta nuevamente.', false);
        print('Network Error: $e');
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
        errorMessage = errorBody['error'] ?? errorBody['detail'] ?? errorMessage;
      }
    } catch (_) {}
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
              )).toList(),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
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
                color: Colors.white.withOpacity(0.1),
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
                color: Colors.white.withOpacity(0.1),
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
              color: Colors.white.withOpacity(0.1),
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
              color: Colors.black.withOpacity(0.1),
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
              color: Colors.black.withOpacity(0.1),
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
                color: Colors.white.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
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
                  hintText: 'Pregunta sobre tus fresas...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
        ],
      ),
    );
  }
}