extends Node
class_name Main_TwitchGameBridge

## TwitchGameBridge
##
## Handles Twitch integration for the main game scene:
## - Authentication and setup
## - Chat command handling (!joinqueue)
## - SurvivorNameManager priority pool management

@export var ui: MainUI
@export var joinqueue_command: TwitchCommand

func _ready() -> void:
  if not SettingsManager.twitch_enabled:
    return

  MyLogger.info("TwitchBridge", "Twitch integration enabled - setting up Twitch connection")
  var setup_successful: bool = await Twitch.setup()

  if setup_successful:
    MyLogger.info("TwitchBridge", "Twitch setup successful")
    var me = await Twitch.get_current_user()
    MyLogger.info("TwitchBridge", "Twitch authenticated as %s (ID: %s)" % [me.display_name, me.id])

    if SettingsManager.twitch_welcome_message != "":
      Twitch.chat(SettingsManager.twitch_welcome_message)

    Twitch.api.unauthenticated.connect(_on_twitch_unauthenticated)

    # Set up eventsub to listen to chat
    Twitch.eventsub.subscribe(
      TwitchEventsubConfig.create(TwitchEventsubDefinition.CHANNEL_CHAT_MESSAGE, {"broadcaster_user_id": me.id, "user_id": me.id}),
    )

    if joinqueue_command:
      joinqueue_command.command_received.connect(_on_joinqueue_command_received)
  else:
    # Display a message to the user if Twitch setup failed, but don't disable the game
    # features since Twitch is optional
    MyLogger.error("TwitchBridge", "Twitch setup failed - Twitch features will be unavailable")
    if ui:
      ui.call_deferred("show_problem_message", "Twitch integration failed to set up. Twitch features will be unavailable. Please check the logs for more details.")


func _on_twitch_unauthenticated() -> void:
  MyLogger.warn("TwitchBridge", "Twitch token lost during gameplay - Twitch features will be unavailable until re-authenticated")
  if ui:
    ui.call_deferred("show_problem_message", "Twitch connection was lost. Open Settings to reconnect.")


func _on_joinqueue_command_received(from_username: String, _info: TwitchCommandInfo, _arguments: PackedStringArray) -> void:
  MyLogger.info("TwitchBridge", "Received !joinqueue command from %s" % from_username)
  var survivor_name := from_username

  if SurvivorNameManager.add_name_to_priority_pool(survivor_name):
    MyLogger.info("TwitchBridge", "Added survivor name '%s' to priority pool" % survivor_name)
    Twitch.chat("Thanks @%s! Your survivor name '%s' has been added to the priority pool for the next scenario." % [from_username, survivor_name])
  else:
    MyLogger.warn("TwitchBridge", "Survivor name '%s' is already in the priority pool" % survivor_name)
    Twitch.chat("@%s, the survivor name '%s' is already in the priority pool." % [from_username, survivor_name])
