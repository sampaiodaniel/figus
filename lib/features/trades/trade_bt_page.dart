import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/figus_colors.dart';
import '../../core/widgets/figus_app_bar.dart';
import '../../data/providers.dart';
import 'qr_codec.dart';

/// Bluetooth/Wi-Fi P2P trade flow. Both peers pick a role (Anfitrião —
/// advertises — or Visitante — discovers) and the matcher fires as soon
/// as one peer has the other's inventory. Uses Google Nearby Connections,
/// which is Android-only; on iOS we show an "em breve" placeholder.
class TradeBtPage extends ConsumerStatefulWidget {
  const TradeBtPage({super.key});
  @override
  ConsumerState<TradeBtPage> createState() => _TradeBtPageState();
}

enum _Role { undecided, advertiser, discoverer }

class _TradeBtPageState extends ConsumerState<TradeBtPage> {
  final _strategy = Strategy.P2P_POINT_TO_POINT;
  // Service id is just an arbitrary unique identifier — both peers need to
  // agree on it for the Nearby SDK to discover the right group.
  static const _serviceId = 'com.danielsampaio.figus.trade';

  _Role _role = _Role.undecided;
  String? _myName;
  String _status = 'Aguardando…';
  String? _error;
  final _peers = <String, String>{}; // endpointId → endpointName

  // Endpoint ID we're connected to, used to send our payload back after
  // a successful match.
  String? _connectedId;

  // Buffer for streamed payloads (Nearby chunks anything > 32KB).
  final _payloadBuffers = <int, List<int>>{};

  @override
  void dispose() {
    _stopAll();
    super.dispose();
  }

  Future<void> _stopAll() async {
    try {
      await Nearby().stopAdvertising();
    } catch (_) {}
    try {
      await Nearby().stopDiscovery();
    } catch (_) {}
    try {
      await Nearby().stopAllEndpoints();
    } catch (_) {}
  }

  Future<bool> _requestPerms() async {
    // Newer Androids need the *_ADVERTISE / *_CONNECT / *_SCAN trio plus
    // NEARBY_WIFI_DEVICES; older ones (<12) need LOCATION + classic
    // Bluetooth perms. permission_handler maps to the right ones.
    final perms = <Permission>[
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
      Permission.locationWhenInUse,
    ];
    var allGranted = true;
    for (final p in perms) {
      final status = await p.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        // location is only required on Android 11-, so tolerate denial
        // on newer devices.
        if (p != Permission.locationWhenInUse) allGranted = false;
      }
    }
    return allGranted;
  }

  Future<void> _startAdvertising() async {
    setState(() {
      _error = null;
      _status = 'Iniciando anúncio…';
    });
    if (!await _requestPerms()) {
      setState(() => _error =
          'Sem permissão de Bluetooth/Local. Abra as configurações do app e libere.');
      return;
    }
    _myName = await _profileLabel();
    try {
      await Nearby().startAdvertising(
        _myName!,
        _strategy,
        serviceId: _serviceId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            _connectedId = id;
            _sendMyInventory();
            setState(() => _status = 'Conectado a $_myName — trocando inventários…');
          } else {
            setState(() => _status = 'Conexão falhou: $status');
          }
        },
        onDisconnected: (id) {
          if (mounted) setState(() => _status = 'Desconectado.');
        },
      );
      setState(() {
        _role = _Role.advertiser;
        _status = 'Aguardando alguém te encontrar…';
      });
    } catch (e) {
      setState(() => _error = 'Erro ao anunciar: $e');
    }
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _error = null;
      _status = 'Procurando aparelhos por perto…';
      _peers.clear();
    });
    if (!await _requestPerms()) {
      setState(() => _error =
          'Sem permissão de Bluetooth/Local. Abra as configurações do app e libere.');
      return;
    }
    _myName = await _profileLabel();
    try {
      await Nearby().startDiscovery(
        _myName!,
        _strategy,
        serviceId: _serviceId,
        onEndpointFound: (id, name, _) {
          if (!mounted) return;
          setState(() => _peers[id] = name);
        },
        onEndpointLost: (id) {
          if (!mounted || id == null) return;
          setState(() => _peers.remove(id));
        },
      );
      setState(() => _role = _Role.discoverer);
    } catch (e) {
      setState(() => _error = 'Erro ao procurar: $e');
    }
  }

  Future<void> _connectTo(String endpointId) async {
    setState(() => _status = 'Conectando a $endpointId…');
    try {
      await Nearby().requestConnection(
        _myName ?? 'Figus',
        endpointId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            _connectedId = id;
            _sendMyInventory();
            setState(() => _status = 'Conectado — enviando inventário…');
          } else {
            setState(() => _status = 'Falhou: $status');
          }
        },
        onDisconnected: (id) {
          if (mounted) setState(() => _status = 'Desconectado.');
        },
      );
    } catch (e) {
      setState(() => _error = 'Erro ao conectar: $e');
    }
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    // Auto-accept — both ends agreed via the role selection UI.
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {
        if (payload.bytes != null) {
          _handlePayloadBytes(payload.bytes!);
        }
      },
      onPayloadTransferUpdate: (endpointId, update) {
        // Streamed BYTES payloads come whole in onPayLoadRecieved; this
        // callback only matters for FILE/STREAM types which we don't use.
      },
    );
  }

  void _handlePayloadBytes(Uint8List bytes) {
    final str = utf8.decode(bytes, allowMalformed: true);
    _onInventoryReceived(str);
  }

  Future<void> _sendMyInventory() async {
    if (_connectedId == null) return;
    try {
      final db = ref.read(databaseProvider);
      final payload = await TradeQrCodec.encodeFromDb(db);
      final bytes = Uint8List.fromList(utf8.encode(payload));
      await Nearby().sendBytesPayload(_connectedId!, bytes);
    } catch (e) {
      setState(() => _error = 'Erro ao enviar inventário: $e');
    }
  }

  Future<void> _onInventoryReceived(String payload) async {
    try {
      final db = ref.read(databaseProvider);
      final friend = await TradeQrCodec.decodeFromQr(payload, db);
      if (!mounted) return;
      // We've got the other side — navigate to compare which will run the
      // matcher and show suggestions. Disconnect after handing off so the
      // page doesn't keep the BT link alive in the background.
      await _stopAll();
      if (mounted) context.go('/compare', extra: friend);
    } catch (e) {
      setState(() => _error = 'Inventário inválido recebido: $e');
    }
  }

  Future<String> _profileLabel() async {
    try {
      final p = await ref.read(profileRepoProvider).active();
      return p.name.isEmpty ? 'Figus' : p.name;
    } catch (_) {
      return 'Figus';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    // iOS doesn't have Nearby Connections — show a placeholder.
    if (!kIsWeb && Platform.isIOS) {
      return Scaffold(
        appBar: const FigusAppBar(title: 'Trocar por Bluetooth'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'A troca por Bluetooth está disponível só no Android por '
              'enquanto. Use o QR ou o "Comparar inventário" pra trocar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textMuted, height: 1.5),
            ),
          ),
        ),
      );
    }
    if (kIsWeb) {
      return Scaffold(
        appBar: const FigusAppBar(title: 'Trocar por Bluetooth'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'A troca por Bluetooth só funciona no app instalado '
              '(Android). No browser, use o QR Code.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textMuted, height: 1.5),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const FigusAppBar(title: 'Trocar por Bluetooth'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _role == _Role.undecided
              ? _buildRolePicker(c)
              : _buildActiveSession(c),
        ),
      ),
    );
  }

  Widget _buildRolePicker(FigusColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.accent.withValues(alpha: 0.25)),
          ),
          child: Text(
            'Combine com o amigo: 1 escolhe "Anunciar" e o outro escolhe '
            '"Procurar". Quando o app do amigo aparecer, toque pra conectar '
            'e os inventários trocam automaticamente.',
            style: TextStyle(color: c.text, height: 1.4, fontSize: 13),
          ),
        ),
        const SizedBox(height: 20),
        _RoleButton(
          icon: Icons.broadcast_on_personal_rounded,
          title: 'Anunciar',
          sub: 'Outros vão me encontrar pelo nome do meu perfil',
          accent: c.accent,
          onTap: _startAdvertising,
        ),
        const SizedBox(height: 12),
        _RoleButton(
          icon: Icons.radar_rounded,
          title: 'Procurar',
          sub: 'Mostra a lista de amigos anunciando por perto',
          accent: c.accent,
          onTap: _startDiscovery,
        ),
        const SizedBox(height: 20),
        Text(
          'Funciona sem internet, mas precisa de Bluetooth ligado.',
          textAlign: TextAlign.center,
          style: TextStyle(color: c.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildActiveSession(FigusColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.cardAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(_status, style: TextStyle(color: c.text))),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ],
        if (_role == _Role.discoverer) ...[
          const SizedBox(height: 16),
          Text(
            'Aparelhos por perto',
            style: TextStyle(
              color: c.textMuted,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _peers.isEmpty
                ? Center(
                    child: Text(
                      'Procurando…',
                      style: TextStyle(color: c.textMuted, fontSize: 13),
                    ),
                  )
                : ListView(
                    children: [
                      for (final e in _peers.entries)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.smartphone_rounded),
                            title: Text(e.value),
                            subtitle: Text('ID ${e.key.substring(0, 6)}…'),
                            trailing: const Icon(Icons.handshake_rounded),
                            onTap: () => _connectTo(e.key),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.close_rounded),
          label: const Text('Cancelar'),
          onPressed: () async {
            await _stopAll();
            if (mounted) setState(() => _role = _Role.undecided);
          },
        ),
      ],
    );
  }
}

class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final Color accent;
  final VoidCallback onTap;
  const _RoleButton({
    required this.icon,
    required this.title,
    required this.sub,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: c.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(color: c.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: accent.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
