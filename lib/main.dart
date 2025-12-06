import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ElevadorApp());
}

class ElevadorApp extends StatelessWidget {
  const ElevadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elevadores con Threads',
      home: ElevadorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ElevadorScreen extends StatefulWidget {
  @override
  State<ElevadorScreen> createState() => _ElevadorScreenState();
}

class _ElevadorScreenState extends State<ElevadorScreen> {
  int elev1 = 2;
  int elev2 = 5;
  int userFloor = 0;

  String log = "";

  void logMsg(String msg) {
    setState(() => log += "$msg\n");
  }

  // =======================================================
  // =============     WORKERS / THREADS     ===============
  // =======================================================

  /// Thread para elevador 1
  static void elevador1Thread(Map data) async {
    int dondeVa = data["target"];
    int pos = data["pos"];
    int distOtro = data["distOther"];
    SendPort port = data["port"];

    int dist1 = (pos - dondeVa).abs();

    if (dist1 > distOtro) {
      port.send({"tipo": 0, "msg": "Elevador 2 está más cerca", "pos": pos});
      return;
    }
    
    while (pos != dondeVa) {
      await Future.delayed(const Duration(milliseconds: 500));
      pos += (pos > dondeVa) ? -1 : 1;
      port.send({"tipo": 1, "msg": "Elevador 1 en piso $pos", "pos": pos});
    }

    port.send({"tipo": 2, "msg": "Elevador 1 llegó al piso $dondeVa", "pos": pos});
  }

  /// Thread para elevador 2
  static void elevador2Thread(Map data) async {
    int dondeVa = data["target"];
    int pos = data["pos"];
    int distOtro = data["distOther"];
    SendPort port = data["port"];

    int dist2 = (pos - dondeVa).abs();

    if (dist2 > distOtro) {
      port.send({"tipo": 0, "msg": "Elevador 1 está más cerca", "pos": pos});
      return;
    }

    while (pos != dondeVa) {
      await Future.delayed(const Duration(milliseconds: 500));
      pos += (pos > dondeVa) ? -1 : 1;
      port.send({"tipo": 1, "msg": "Elevador 2 en piso $pos", "pos": pos});
    }

    port.send({"tipo": 2, "msg": "Elevador 2 llegó al piso $dondeVa", "pos": pos});
  }

  // =======================================================
  // =============  FUNCIÓN PRINCIPAL (FASE 2)   ===========
  // =======================================================

  Future<void> llamarElevadores() async {
    logMsg("Llamando elevadores al piso $userFloor...");

    int dist1 = (elev1 - userFloor).abs();
    int dist2 = (elev2 - userFloor).abs();

    ReceivePort r1 = ReceivePort();
    ReceivePort r2 = ReceivePort();

    await Isolate.spawn(elevador1Thread, {
      "target": userFloor,
      "pos": elev1,
      "distOther": dist2,
      "port": r1.sendPort,
    });

    await Isolate.spawn(elevador2Thread, {
      "target": userFloor,
      "pos": elev2,
      "distOther": dist1,
      "port": r2.sendPort,
    });

    r1.listen((data) {
      logMsg(data["msg"]);
      if (data["tipo"] != 0) {
        setState(() => elev1 = data["pos"]);
      }
    });

    r2.listen((data) {
      logMsg(data["msg"]);
      if (data["tipo"] != 0) {
        setState(() => elev2 = data["pos"]);
      }
    });

    await Future.delayed(const Duration(seconds: 4));
    pedirDestino();
  }

  // =======================================================
  // ============= VALIDACIÓN DE RANGO Y DESTINO ===========
  // =======================================================

  Future<void> pedirDestino() async {
    int destino = await pedirNumero("¿A qué piso va?");
    int rango = await pedirRango();

    if (destino > 6) {
      logMsg("Ese nivel no existe");
      return;
    }

    if (rango == 1 && destino > 2) {
      logMsg("No tiene acceso a ese nivel");
      return;
    }

    if (rango == 2 && destino > 4) {
      logMsg("No tiene acceso a ese nivel");
      return;
    }

    logMsg("Vamos camino al piso $destino");
  }

  // =======================================================
  // =============        UI AUXILIAR          =============
  // =======================================================

  Future<int> pedirNumero(String title) async {
    int value = 0;

    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            keyboardType: TextInputType.number,
            onChanged: (v) => value = int.tryParse(v) ?? 0,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, value),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<int> pedirRango() async {
    int r = 1;

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("¿Cuál es su rango?"),
              content: DropdownButton<int>(
                value: r,
                items: const [
                  DropdownMenuItem(value: 1, child: Text("1 Empleado")),
                  DropdownMenuItem(value: 2, child: Text("2 Super empleado")),
                  DropdownMenuItem(value: 3, child: Text("3 Mega empleado")),
                ],
                onChanged: (v) => setState(() => r = v ?? 1),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, r),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      },
    );

    return result ?? 1;
  }

  // =======================================================
  // =========================== UI ========================
  // =======================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Elevadores con Threads Reales")),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text("Elevador 1: piso $elev1"),
            Text("Elevador 2: piso $elev2"),
            const SizedBox(height: 20),

            TextField(
  decoration: const InputDecoration(
    labelText: "¿En qué piso estás?",
  ),
  keyboardType: TextInputType.number,
  onChanged: (v) {
    setState(() {
      final n = int.tryParse(v);

      if (n == null) {
        userFloor = 0; // inválido
        return;
      }

      if (n > 6) {
        logMsg("Este piso no existe");
        userFloor = 0; // marca como inválido
        return;
      }

      userFloor = n; // válido
    });
  },
),

ElevatedButton(
  onPressed: (userFloor == 0)
      ? null
      : llamarElevadores,
  child: const Text("Pedir elevadores"),
),

            const SizedBox(height: 20),
            const Text("Log:"),
            Expanded(
              child: SingleChildScrollView(
                child: Text(log),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
