import '../entities/dispatch.dart';
import '../enums/dispatch_status.dart';

abstract class DispatchRepository {
  Future<Dispatch> getDispatchById(String id);
  Future<List<Dispatch>> getActiveDispatchesForDriver(String driverId);
  Future<Dispatch> createDispatch(Dispatch dispatch);
  Future<void> updateStatus(String dispatchId, DispatchStatus status, {DateTime? timestamp});
}
