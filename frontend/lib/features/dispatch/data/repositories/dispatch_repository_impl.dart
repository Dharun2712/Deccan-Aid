import '../../domain/entities/dispatch.dart';
import '../../domain/enums/dispatch_status.dart';
import '../../domain/repositories/dispatch_repository.dart';

class DispatchRepositoryImpl implements DispatchRepository {
  // Mocked for now; typically uses Dio/http to call FastAPI backend
  final List<Dispatch> _mockDispatches = [];

  @override
  Future<Dispatch> getDispatchById(String id) async {
    return _mockDispatches.firstWhere((d) => d.id == id, orElse: () => throw Exception('Dispatch not found'));
  }

  @override
  Future<List<Dispatch>> getActiveDispatchesForDriver(String driverId) async {
    return _mockDispatches.where((d) => d.driverId == driverId && d.status != DispatchStatus.completed && d.status != DispatchStatus.cancelled).toList();
  }

  @override
  Future<Dispatch> createDispatch(Dispatch dispatch) async {
    _mockDispatches.add(dispatch);
    return dispatch;
  }

  @override
  Future<void> updateStatus(String dispatchId, DispatchStatus status, {DateTime? timestamp}) async {
    // API Call to PATCH /dispatches/{id}/{action}
  }
}
