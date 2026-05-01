import 'enums.dart';
import 'model_utils.dart';

class ServiceRecord {
  final String id;
  final String serviceType;
  final String customerName;
  final String customerPhone;
  final double serviceCharge;
  final ServiceStatus status;
  final double cashCost;
  final String sparePartProductId;
  final String sparePartProductName;
  final int sparePartQuantity;
  final double sparePartUnitCost;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdByUid;
  final String createdByName;

  const ServiceRecord({
    required this.id,
    required this.serviceType,
    required this.customerName,
    required this.customerPhone,
    required this.serviceCharge,
    required this.status,
    required this.cashCost,
    required this.sparePartProductId,
    required this.sparePartProductName,
    required this.sparePartQuantity,
    required this.sparePartUnitCost,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByUid,
    required this.createdByName,
  });

  factory ServiceRecord.fromMap(Map<String, dynamic> map, String id) {
    return ServiceRecord(
      id: id,
      serviceType: map['serviceType']?.toString() ?? '',
      customerName: map['customerName']?.toString() ?? '',
      customerPhone: map['customerPhone']?.toString() ?? '',
      serviceCharge: readDouble(map['serviceCharge']),
      status: readServiceStatus(map['status']),
      cashCost: readDouble(map['cashCost']),
      sparePartProductId: map['sparePartProductId']?.toString() ?? '',
      sparePartProductName: map['sparePartProductName']?.toString() ?? '',
      sparePartQuantity: readInt(map['sparePartQuantity']),
      sparePartUnitCost: readDouble(map['sparePartUnitCost']),
      note: map['note']?.toString() ?? '',
      createdAt: readDateTime(map['createdAt']),
      updatedAt: readDateTime(map['updatedAt'] ?? map['createdAt']),
      createdByUid: map['createdByUid']?.toString() ?? '',
      createdByName: map['createdByName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceType': serviceType,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'serviceCharge': serviceCharge,
      'status': status.name,
      'cashCost': cashCost,
      'sparePartProductId': sparePartProductId,
      'sparePartProductName': sparePartProductName,
      'sparePartQuantity': sparePartQuantity,
      'sparePartUnitCost': sparePartUnitCost,
      'sparePartCost': sparePartCost,
      'note': note,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdByUid': createdByUid,
      'createdByName': createdByName,
    };
  }

  ServiceRecord copyWith({
    String? id,
    String? serviceType,
    String? customerName,
    String? customerPhone,
    double? serviceCharge,
    ServiceStatus? status,
    double? cashCost,
    String? sparePartProductId,
    String? sparePartProductName,
    int? sparePartQuantity,
    double? sparePartUnitCost,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByUid,
    String? createdByName,
  }) {
    return ServiceRecord(
      id: id ?? this.id,
      serviceType: serviceType ?? this.serviceType,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      status: status ?? this.status,
      cashCost: cashCost ?? this.cashCost,
      sparePartProductId: sparePartProductId ?? this.sparePartProductId,
      sparePartProductName: sparePartProductName ?? this.sparePartProductName,
      sparePartQuantity: sparePartQuantity ?? this.sparePartQuantity,
      sparePartUnitCost: sparePartUnitCost ?? this.sparePartUnitCost,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByUid: createdByUid ?? this.createdByUid,
      createdByName: createdByName ?? this.createdByName,
    );
  }

  double get sparePartCost => sparePartQuantity * sparePartUnitCost;

  double get totalCost => cashCost + sparePartCost;

  double get netIncome => serviceCharge - totalCost;

  bool get isPaid => status == ServiceStatus.completedPaid;

  bool get isCompleted => status != ServiceStatus.pending;
}
