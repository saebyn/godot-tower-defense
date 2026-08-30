# Navigation Performance Metrics

Zombie navigation instrumentation is exposed through Godot's built-in **Debugger → Monitors** panel while the game is running. Expand the **Navigation** category and select the metrics you want to graph.

The instrumentation is intentionally observational: it records the navigation work the game already performs without changing targeting or pathing behavior.

The custom monitors are registered by the process-lifetime `GameManager` autoload. They remain registered while moving between gameplay, menus, and scenarios, reporting zero-rate values when no navigation work is occurring. Their graph history therefore survives scene changes within a single run. Stopping the game process removes the runtime custom monitors and their session history, as expected for Godot custom performance monitors.

## Metrics

| Monitor | Meaning |
| --- | --- |
| Active Zombies | Number of live zombie navigation agents. |
| Target Sets per Second | Calls from zombie targeting code to `NavigationAgent3D.set_target_position()`. |
| Duplicate Target Sets per Second | Target sets where the requested position is unchanged from the previous request for that zombie. |
| Duplicate Target Set Percent | Percentage of target sets that repeat the previous requested position. |
| Explicit Path Queries per Second | Direct `NavigationServer3D.map_get_path()` calls made by target reachability checks. |
| Explicit Path Query Time ms per Second | Total wall-clock time spent inside those explicit path queries during the sample window. |
| Explicit Path Query Max ms | Slowest individual explicit path query in the latest sample window. |
| Path Changes per Second | `NavigationAgent3D.path_changed` signals across all zombies. This indicates loaded paths actually being updated. |
| Agent Path Update Time ms per Second | Total wall-clock time spent in zombie calls to `get_next_path_position()` during the sample window. This includes the agent-side navigation update work performed by that call; it is not a pure A* CPU measurement. |
| Agent Path Update Max ms | Slowest individual `get_next_path_position()` call in the latest sample window. |
| Reachability Checks per Second | Explicit reachability checks from targeting and fallback behavior. |
| Fallback Checks per Second | Fallback-path checks launched by zombie targeting. |
| Rebake Requests per Second | Requests made to rebake the navigation mesh, including requests queued while a bake is active. |
| Rebakes Started per Second | Navigation mesh bakes actually started. |
| Last Rebake ms | Wall-clock duration of the most recently completed navigation mesh bake started by the navigation controller. |

Rates and timing totals use one-second aggregation windows so the Debugger graphs remain readable and the instrumentation itself stays lightweight.

## Reviewing a gameplay run

For a useful baseline, graph these together first:

- **Active Zombies**
- **Target Sets per Second**
- **Duplicate Target Set Percent**
- **Path Changes per Second**
- **Agent Path Update Time ms per Second**
- **Explicit Path Query Time ms per Second**
- **Last Rebake ms**

Also graph Godot's built-in frame/physics/navigation monitors alongside them. The custom timings measure wall-clock time around specific APIs used by the game; Godot's built-in monitors provide the broader frame context.

When testing an environment change such as placing a building, look for correlation between the rebake, a burst of path changes, navigation API time, and frame time. When testing scale, increase zombie count while watching whether navigation time grows enough to affect the frame budget.

## Comparing changes over time

The Godot monitor graphs are run-local; they are not a historical benchmark database. For comparisons between commits, use the same scenario and workload and record a small baseline table in the relevant issue or PR, for example:

| Metric | Baseline | Candidate |
| --- | ---: | ---: |
| Active zombies | | |
| Target sets/s | | |
| Duplicate target sets | | |
| Path changes/s | | |
| Agent path update ms/s | | |
| Explicit path query ms/s | | |
| Last rebake ms | | |
| Frame time / FPS | | |

This keeps navigation optimization evidence-driven: if a change removes large amounts of redundant work but does not affect meaningful frame or response metrics at expected gameplay scale, we can stop there rather than escalating to a more complex pathfinding architecture.
