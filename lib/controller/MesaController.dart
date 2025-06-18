// lib/controllers/mesa_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Mesa.dart';

class MesaController {
  final CollectionReference _mesasRef =
  FirebaseFirestore.instance.collection('mesas');

  Future<void> cadastrarMesa(Mesa mesa) async {
    await _mesasRef.add({
      'numero': mesa.numero,
      'status': mesa.Status,
    });
  }

  Future<void> atualizarStatusMesa(String id, String status) async {
    await _mesasRef.doc(id).update({
      'status': status,
    });
  }
}