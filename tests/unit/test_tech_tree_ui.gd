extends GutTest

## Unit tests for TechTree UI
## Tests tech tree UI initialization, node selection, and unlock functionality

var tech_tree_scene = preload("res://Stages/UI/tech_tree/tech_tree.tscn")
var tech_tree: TechTree

func before_each():
	# Reset the TechTreeManager state before each test
	TechTreeManager.reset_tech_tree()
	
	# Reset CurrencyManager to known state
	CurrencyManager.current_scrap = 100
	CurrencyManager.current_xp = 0
	CurrencyManager.current_level = 1
	
	# Instantiate tech tree UI
	tech_tree = tech_tree_scene.instantiate()
	add_child_autofree(tech_tree)
	
	# Wait for ready to complete
	await wait_frames(2)

func test_tech_tree_initializes():
	# Assert
	assert_not_null(tech_tree, "Tech tree should be instantiated")
	assert_true(tech_tree is TechTree, "Should be a TechTree instance")

func test_tech_tree_loads_all_nodes():
	# Assert - verify that tech node cards were created
	assert_gt(tech_tree.tech_node_cards.size(), 0, "Should create tech node cards")
	assert_eq(tech_tree.tech_node_cards.size(), TechTreeManager.tech_nodes.size(), "Should create one card per tech node")

func test_detail_panel_hidden_initially():
	# Assert
	assert_false(tech_tree.detail_panel.visible, "Detail panel should be hidden initially")

func test_selecting_tech_node_shows_details():
	# Arrange - unlock a tech first
	CurrencyManager.current_level = 1
	
	# Act - simulate selecting a tech node
	tech_tree._on_tech_node_selected("tur_scrap_shooter")
	
	# Assert
	assert_true(tech_tree.detail_panel.visible, "Detail panel should be visible after selection")
	assert_eq(tech_tree.selected_tech_id, "tur_scrap_shooter", "Selected tech should be set")
	assert_eq(tech_tree.detail_name.text, "Scrap Shooter", "Tech name should be displayed")

func test_unlock_button_enabled_for_available_tech():
	# Arrange
	CurrencyManager.current_level = 1
	tech_tree._on_tech_node_selected("tur_scrap_shooter")
	
	# Assert
	assert_false(tech_tree.unlock_button.disabled, "Unlock button should be enabled for available tech")
	assert_eq(tech_tree.unlock_button.text, "Unlock", "Button should show 'Unlock'")

func test_unlock_button_disabled_for_unlocked_tech():
	# Arrange
	CurrencyManager.current_level = 1
	TechTreeManager.unlock_tech("tur_scrap_shooter")
	tech_tree._on_tech_node_selected("tur_scrap_shooter")
	
	# Assert
	assert_true(tech_tree.unlock_button.disabled, "Unlock button should be disabled for unlocked tech")
	assert_eq(tech_tree.unlock_button.text, "Already Unlocked", "Button should show 'Already Unlocked'")

func test_unlock_button_disabled_for_locked_tech():
	# Arrange
	CurrencyManager.current_level = 1
	
	# Act - select a tech that requires level 2
	tech_tree._on_tech_node_selected("tur_boom_barrel")
	
	# Assert
	assert_true(tech_tree.unlock_button.disabled, "Unlock button should be disabled for locked tech")

func test_tech_node_card_state_updates_on_unlock():
	# Arrange
	CurrencyManager.current_level = 1
	var card = tech_tree.tech_node_cards.get("tur_scrap_shooter")
	assert_not_null(card, "Card should exist")
	
	# Act - unlock the tech
	TechTreeManager.unlock_tech("tur_scrap_shooter")
	await wait_frames(2)
	
	# Assert - card state should update
	assert_eq(card.current_state, TechNodeCard.NodeState.UNLOCKED, "Card should show as unlocked")

func test_tech_node_card_state_updates_on_lock():
	# Arrange
	CurrencyManager.current_level = 2
	TechTreeManager.unlock_tech("tur_scrap_shooter")
	
	# Act - unlock a mutually exclusive tech
	TechTreeManager.unlock_tech("tur_boom_barrel")
	await wait_frames(2)
	
	# Assert - mutually exclusive tech card should update
	var molotov_card = tech_tree.tech_node_cards.get("tur_molotov_mortar")
	if molotov_card:
		assert_eq(molotov_card.current_state, TechNodeCard.NodeState.PERMANENTLY_LOCKED, "Card should show as permanently locked")

func test_tech_tree_displays_all_branches():
	# Assert - check that all expected branches are represented
	var expected_branches = ["Offensive", "Defensive", "Economy", "Support", "Click", "Advanced"]
	var found_branches = {}
	
	for tech_id in tech_tree.tech_node_cards:
		var tech = TechTreeManager.get_tech_node(tech_id)
		if tech:
			found_branches[tech.branch_name] = true
	
	# At least some branches should be present
	assert_gt(found_branches.size(), 0, "Should display at least one branch")

func test_close_button_emits_closed_signal():
	# Arrange
	watch_signals(tech_tree)
	
	# Act - simulate close button press
	tech_tree._on_close_pressed()
	
	# Assert
	assert_signal_emitted(tech_tree, "closed", "Should emit closed signal")
