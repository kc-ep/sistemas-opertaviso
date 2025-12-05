import 'package:flutter/material.dart';

void main() {
  runApp(const ElevatorApp());
}

class ElevatorApp extends StatelessWidget {
  const ElevatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Elevadores",
      home: ElevatorMenu(),
    );
  }
}

class ElevatorMenu extends StatefulWidget {
  @override
  State<ElevatorMenu> createState() => _ElevatorMenuState();
}

class _ElevatorMenuState extends State<ElevatorMenu> {
  int elevator1 = 2;
  int elevator2 = 5;
  int userFloor = 0;

  String log = "";

  void addLog(String text) {
    setState(() {
      log += "$text\n";
    });
  }

  // Simula tiempo como this_thread::sleep_for
  Future<void> wait(int ms) async {
    await Future.delayed(Duration(milliseconds: ms));
  }

  // ====== PAPU (Elevador 1) ======
  Future<void> papu(int target) async {
    int dist1 = (elevator1 - target).abs();
    int dist2 = (elevator2 - target).abs();

    // Si elevador 2 es más cercano → no usar este elevador
    if (dist1 > dist2) {
      addLog("Elevador 2 viene mejor");
      return;
    }

    addLog("Elevador 1 llegando...");

    while (elevator1 != target) {
      addLog("Elevador 1 en piso $elevator1");

      if (elevator1 > target) {
        elevator1--;
      } else {
        elevator1++;
      }

      setState(() {});
      await wait(500);
    }

    addLog("Elevador 1 llegó al piso $target");
    await pedirDestino(1);
  }

  // ====== PAPU2 (Elevador 2) ======
  Future<void> papu2(int target) async {
    int dist2 = (elevator2 - target).abs();
    int dist1 = (elevator1 - target).abs();

    if (dist2 > dist1) {
      addLog("Elevador 1 viene mejor");
      return;
    }

    addLog("Elevador 2 llegando...");

    while (elevator2 != target) {
      addLog("Elevador 2 en piso $elevator2");

      if (elevator2 > target) {
        elevator2--;
      } else {
        elevator2++;
      }

      setState(() {});
      await wait(500);
    }

    addLog("Elevador 2 llegó al piso $target");
    await pedirDestino(2);
  }

  // ====== Pedir destino con rango ======
  Future<void> pedirDestino(int elev) async {
    int newFloor = await showDialog(
      context: context,
      builder: (context) {
        int temp = 0;
        return AlertDialog(
          title: const Text("¿A qué piso quiere ir?"),
          content: TextField(
            keyboardType: TextInputType.number,
            onChanged: (v) => temp = int.tryParse(v) ?? 0,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, temp),
                child: const Text("OK"))
          ],
        );
      },
    );

    int rango = await showDialog(
      context: context,
      builder: (context) {
        int r = 1;
        return AlertDialog(
          title: const Text("¿Cuál es su rango?"),
          content: DropdownButton<int>(
            value: 1,
            items: const [
              DropdownMenuItem(value: 1, child: Text("1 Empleado")),
              DropdownMenuItem(value: 2, child: Text("2 Super empleado")),
              DropdownMenuItem(value: 3, child: Text("3 Mega empleado")),
            ],
            onChanged: (v) => r = v ?? 1,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, r), child: const Text("OK")),
          ],
        );
      },
    );

    // Validaciones idénticas a tu C++
    if (newFloor > 6) {
      addLog("Ese nivel no existe");
      return;
    }
    if (rango == 1 && newFloor > 2) {
      addLog("No tiene acceso a ese nivel");
      return;
    }
    if (rango == 2 && newFloor > 4) {
      addLog("No tiene acceso a ese nivel");
      return;
    }

    addLog("Elevador $elev yendo al piso $newFloor...");
  }

  // ====== Solicitar elevador (fase2) ======
  Future<void> callElevator() async {
    addLog("Llamando elevador al piso $userFloor");

    await Future.wait([
      papu(userFloor),
      papu2(userFloor),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Control de Elevadores")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text("Elevador 1: piso $elevator1"),
            Text("Elevador 2: piso $elevator2"),
            const SizedBox(height: 20),

            TextField(
              decoration: const InputDecoration(labelText: "¿En qué piso estás?"),
              keyboardType: TextInputType.number,
              onChanged: (v) => userFloor = int.tryParse(v) ?? 0,
            ),
            ElevatedButton(
              onPressed: callElevator,
              child: const Text("Pedir elevador"),
            ),

            const SizedBox(height: 20),
            const Text("Log:", style: TextStyle(fontWeight: FontWeight.bold)),
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
