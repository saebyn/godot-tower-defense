extends RefCounted
class_name Utility_NavigationMetrics

## Lightweight aggregation for navigation instrumentation.
##
## Call sites record counters and elapsed microseconds. Values are rolled up once
## per second so Godot's custom Performance monitors can graph useful rates
## without emitting per-frame logs.

const SAMPLE_WINDOW_SECONDS := 1.0
const USEC_PER_MSEC := 1000.0

const ACTIVE_ZOMBIES := &"active_zombies"
const TARGET_SETS_PER_SECOND := &"target_sets_per_second"
const DUPLICATE_TARGET_SETS_PER_SECOND := &"duplicate_target_sets_per_second"
const DUPLICATE_TARGET_SET_PERCENT := &"duplicate_target_set_percent"
const EXPLICIT_PATH_QUERIES_PER_SECOND := &"explicit_path_queries_per_second"
const EXPLICIT_PATH_QUERY_TIME_MSEC_PER_SECOND := &"explicit_path_query_time_msec_per_second"
const EXPLICIT_PATH_QUERY_MAX_MSEC := &"explicit_path_query_max_msec"
const PATH_CHANGES_PER_SECOND := &"path_changes_per_second"
const AGENT_PATH_UPDATE_TIME_MSEC_PER_SECOND := &"agent_path_update_time_msec_per_second"
const AGENT_PATH_UPDATE_MAX_MSEC := &"agent_path_update_max_msec"
const REACHABILITY_CHECKS_PER_SECOND := &"reachability_checks_per_second"
const FALLBACK_CHECKS_PER_SECOND := &"fallback_checks_per_second"
const REBAKE_REQUESTS_PER_SECOND := &"rebake_requests_per_second"
const REBAKES_STARTED_PER_SECOND := &"rebakes_started_per_second"
const LAST_REBAKE_MSEC := &"last_rebake_msec"

static var _sample_elapsed: float = 0.0
static var _active_zombies: int = 0

static var _window_target_sets: int = 0
static var _window_duplicate_target_sets: int = 0
static var _window_explicit_path_queries: int = 0
static var _window_explicit_path_query_usec: int = 0
static var _window_explicit_path_query_max_usec: int = 0
static var _window_path_changes: int = 0
static var _window_agent_path_update_usec: int = 0
static var _window_agent_path_update_max_usec: int = 0
static var _window_reachability_checks: int = 0
static var _window_fallback_checks: int = 0
static var _window_rebake_requests: int = 0
static var _window_rebakes_started: int = 0

static var _latest_target_sets_per_second: float = 0.0
static var _latest_duplicate_target_sets_per_second: float = 0.0
static var _latest_duplicate_target_set_percent: float = 0.0
static var _latest_explicit_path_queries_per_second: float = 0.0
static var _latest_explicit_path_query_time_msec_per_second: float = 0.0
static var _latest_explicit_path_query_max_msec: float = 0.0
static var _latest_path_changes_per_second: float = 0.0
static var _latest_agent_path_update_time_msec_per_second: float = 0.0
static var _latest_agent_path_update_max_msec: float = 0.0
static var _latest_reachability_checks_per_second: float = 0.0
static var _latest_fallback_checks_per_second: float = 0.0
static var _latest_rebake_requests_per_second: float = 0.0
static var _latest_rebakes_started_per_second: float = 0.0
static var _last_rebake_msec: float = 0.0


static func reset() -> void:
  _sample_elapsed = 0.0
  _active_zombies = 0

  _window_target_sets = 0
  _window_duplicate_target_sets = 0
  _window_explicit_path_queries = 0
  _window_explicit_path_query_usec = 0
  _window_explicit_path_query_max_usec = 0
  _window_path_changes = 0
  _window_agent_path_update_usec = 0
  _window_agent_path_update_max_usec = 0
  _window_reachability_checks = 0
  _window_fallback_checks = 0
  _window_rebake_requests = 0
  _window_rebakes_started = 0

  _latest_target_sets_per_second = 0.0
  _latest_duplicate_target_sets_per_second = 0.0
  _latest_duplicate_target_set_percent = 0.0
  _latest_explicit_path_queries_per_second = 0.0
  _latest_explicit_path_query_time_msec_per_second = 0.0
  _latest_explicit_path_query_max_msec = 0.0
  _latest_path_changes_per_second = 0.0
  _latest_agent_path_update_time_msec_per_second = 0.0
  _latest_agent_path_update_max_msec = 0.0
  _latest_reachability_checks_per_second = 0.0
  _latest_fallback_checks_per_second = 0.0
  _latest_rebake_requests_per_second = 0.0
  _latest_rebakes_started_per_second = 0.0
  _last_rebake_msec = 0.0


static func update(delta: float) -> void:
  _sample_elapsed += delta
  if _sample_elapsed < SAMPLE_WINDOW_SECONDS:
    return

  var elapsed := _sample_elapsed
  _latest_target_sets_per_second = _window_target_sets / elapsed
  _latest_duplicate_target_sets_per_second = _window_duplicate_target_sets / elapsed
  _latest_duplicate_target_set_percent = (
    100.0 * _window_duplicate_target_sets / _window_target_sets
    if _window_target_sets > 0
    else 0.0
  )
  _latest_explicit_path_queries_per_second = _window_explicit_path_queries / elapsed
  _latest_explicit_path_query_time_msec_per_second = _window_explicit_path_query_usec / USEC_PER_MSEC / elapsed
  _latest_explicit_path_query_max_msec = _window_explicit_path_query_max_usec / USEC_PER_MSEC
  _latest_path_changes_per_second = _window_path_changes / elapsed
  _latest_agent_path_update_time_msec_per_second = _window_agent_path_update_usec / USEC_PER_MSEC / elapsed
  _latest_agent_path_update_max_msec = _window_agent_path_update_max_usec / USEC_PER_MSEC
  _latest_reachability_checks_per_second = _window_reachability_checks / elapsed
  _latest_fallback_checks_per_second = _window_fallback_checks / elapsed
  _latest_rebake_requests_per_second = _window_rebake_requests / elapsed
  _latest_rebakes_started_per_second = _window_rebakes_started / elapsed

  _sample_elapsed = 0.0
  _window_target_sets = 0
  _window_duplicate_target_sets = 0
  _window_explicit_path_queries = 0
  _window_explicit_path_query_usec = 0
  _window_explicit_path_query_max_usec = 0
  _window_path_changes = 0
  _window_agent_path_update_usec = 0
  _window_agent_path_update_max_usec = 0
  _window_reachability_checks = 0
  _window_fallback_checks = 0
  _window_rebake_requests = 0
  _window_rebakes_started = 0


static func register_zombie() -> void:
  _active_zombies += 1


static func unregister_zombie() -> void:
  _active_zombies = maxi(0, _active_zombies - 1)


static func record_target_set(is_duplicate: bool) -> void:
  _window_target_sets += 1
  if is_duplicate:
    _window_duplicate_target_sets += 1


static func record_explicit_path_query(duration_usec: int) -> void:
  _window_explicit_path_queries += 1
  _window_explicit_path_query_usec += duration_usec
  _window_explicit_path_query_max_usec = maxi(_window_explicit_path_query_max_usec, duration_usec)


static func record_path_changed() -> void:
  _window_path_changes += 1


static func record_agent_path_update(duration_usec: int) -> void:
  _window_agent_path_update_usec += duration_usec
  _window_agent_path_update_max_usec = maxi(_window_agent_path_update_max_usec, duration_usec)


static func record_reachability_check() -> void:
  _window_reachability_checks += 1


static func record_fallback_check() -> void:
  _window_fallback_checks += 1


static func record_rebake_requested() -> void:
  _window_rebake_requests += 1


static func record_rebake_started() -> void:
  _window_rebakes_started += 1


static func record_rebake_finished(duration_usec: int) -> void:
  _last_rebake_msec = duration_usec / USEC_PER_MSEC


static func get_metric(metric: StringName) -> float:
  match metric:
    ACTIVE_ZOMBIES:
      return _active_zombies
    TARGET_SETS_PER_SECOND:
      return _latest_target_sets_per_second
    DUPLICATE_TARGET_SETS_PER_SECOND:
      return _latest_duplicate_target_sets_per_second
    DUPLICATE_TARGET_SET_PERCENT:
      return _latest_duplicate_target_set_percent
    EXPLICIT_PATH_QUERIES_PER_SECOND:
      return _latest_explicit_path_queries_per_second
    EXPLICIT_PATH_QUERY_TIME_MSEC_PER_SECOND:
      return _latest_explicit_path_query_time_msec_per_second
    EXPLICIT_PATH_QUERY_MAX_MSEC:
      return _latest_explicit_path_query_max_msec
    PATH_CHANGES_PER_SECOND:
      return _latest_path_changes_per_second
    AGENT_PATH_UPDATE_TIME_MSEC_PER_SECOND:
      return _latest_agent_path_update_time_msec_per_second
    AGENT_PATH_UPDATE_MAX_MSEC:
      return _latest_agent_path_update_max_msec
    REACHABILITY_CHECKS_PER_SECOND:
      return _latest_reachability_checks_per_second
    FALLBACK_CHECKS_PER_SECOND:
      return _latest_fallback_checks_per_second
    REBAKE_REQUESTS_PER_SECOND:
      return _latest_rebake_requests_per_second
    REBAKES_STARTED_PER_SECOND:
      return _latest_rebakes_started_per_second
    LAST_REBAKE_MSEC:
      return _last_rebake_msec
    _:
      return 0.0
