extends GutTest


func before_each() -> void:
  Utility_NavigationMetrics.reset()


func test_target_set_metrics_roll_up_over_sample_window() -> void:
  Utility_NavigationMetrics.record_target_set(false)
  Utility_NavigationMetrics.record_target_set(true)

  Utility_NavigationMetrics.update(1.0)

  assert_eq(Utility_NavigationMetrics.get_metric(Utility_NavigationMetrics.TARGET_SETS_PER_SECOND), 2.0)
  assert_eq(Utility_NavigationMetrics.get_metric(Utility_NavigationMetrics.DUPLICATE_TARGET_SETS_PER_SECOND), 1.0)
  assert_eq(Utility_NavigationMetrics.get_metric(Utility_NavigationMetrics.DUPLICATE_TARGET_SET_PERCENT), 50.0)


func test_path_timing_metrics_report_total_and_maximum_time() -> void:
  Utility_NavigationMetrics.record_explicit_path_query(1500)
  Utility_NavigationMetrics.record_explicit_path_query(2500)
  Utility_NavigationMetrics.record_agent_path_update(750)
  Utility_NavigationMetrics.record_agent_path_update(1250)

  Utility_NavigationMetrics.update(1.0)

  assert_eq(Utility_NavigationMetrics.get_metric(Utility_NavigationMetrics.EXPLICIT_PATH_QUERY_TIME_MSEC_PER_SECOND), 4.0)
  assert_eq(Utility_NavigationMetrics.get_metric(Utility_NavigationMetrics.EXPLICIT_PATH_QUERY_MAX_MSEC), 2.5)
  assert_eq(Utility_NavigationMetrics.get_metric(Utility_NavigationMetrics.AGENT_PATH_UPDATE_TIME_MSEC_PER_SECOND), 2.0)
  assert_eq(Utility_NavigationMetrics.get_metric(Utility_NavigationMetrics.AGENT_PATH_UPDATE_MAX_MSEC), 1.25)


func test_zombie_and_rebake_metrics_track_current_and_latest_values() -> void:
  Utility_NavigationMetrics.register_zombie()
  Utility_NavigationMetrics.register_zombie()
  Utility_NavigationMetrics.unregister_zombie()
  Utility_NavigationMetrics.record_rebake_requested()
  Utility_NavigationMetrics.record_rebake_started()
  Utility_NavigationMetrics.record_rebake_finished(12500)

  Utility_NavigationMetrics.update(1.0)

  assert_eq(Utility_NavigationMetrics.get_metric(Utility_NavigationMetrics.ACTIVE_ZOMBIES), 1.0)
  assert_eq(Utility_NavigationMetrics.get_metric(Utility_NavigationMetrics.REBAKE_REQUESTS_PER_SECOND), 1.0)
  assert_eq(Utility_NavigationMetrics.get_metric(Utility_NavigationMetrics.REBAKES_STARTED_PER_SECOND), 1.0)
  assert_eq(Utility_NavigationMetrics.get_metric(Utility_NavigationMetrics.LAST_REBAKE_MSEC), 12.5)
