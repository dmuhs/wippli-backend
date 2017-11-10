defmodule TelegramBot.Commands do
  use TelegramBot.Router
  use TelegramBot.Commander
  alias TelegramBot.FsmServer
  alias TelegramBot.Commands.Outside, as: Out
  alias WippliBackend.Accounts
  alias WippliBackend.Accounts.User
  alias WippliBackend.Wippli.Participant
  @moduledoc """
  Provides routing for the Telegram bot using the outside module as a logic helper 
  """

  @default_menu %Model.InlineKeyboardMarkup{
    inline_keyboard: [
      [
        %{
          callback_data: "/options join_zone",
          text: "Zone",
        },
        %{
          callback_data: "/options songs_in_zone",
          text: "Playlist",
        },
        %{
          callback_data: "/options request_song",
          text: "Request",
        },
        %{
          callback_data: "/options edit_info",
          text: "Edit Info",
        },
      ],
      []
    ]
  }

  @options_menu %Model.InlineKeyboardMarkup{
    inline_keyboard: [
      [
        %{
          callback_data: "/edit nickname",
          text: "Nickname",
        },
        %{
          callback_data: "/edit phone",
          request_contact: true,
          text: "Phone",
        },

      ],
      []
    ]
  }

  callback_query_command "song" do
    Logger.log :info, "Callback Query Command /song"
    [scope, command, zone_id_string] = String.split(update.callback_query.data)
    zone_id = zone_id_string |> String.to_integer
    case Enum.join([scope, command], " ")   do
      "/song all" ->
        Wippli.get_requests_in_zone(zone_id, true)
      "/song unplayed" ->
        Wippli.get_requests_in_zone(zone_id, false)
    end
  end

  callback_query_command "edit" do
    Logger.log :info, "Callback Query Command /edit"
    case update.callback_query.data do
      "/edit nickname" ->
        Out.advance_fsm(update, :goto_ask_value, :nickname)
        send_message "What's your new nickname?", reply_markup: %Model.ForceReply{force_reply: true}
      "/edit phone" ->
        Out.advance_fsm(update, :goto_ask_value, :phone)
        send_message "Confirm your contact", reply_markup: %Model.ReplyKeyboardMarkup{
          keyboard: [
            [
              %{
                request_contact: true,
                text: "Send phone"
              }
            ],
          ],
          one_time_keyboard: true
}
    end
    answer_callback_query text: "Choose what to edit"
  end

  callback_query_command "options" do
    Logger.log :info, "Callback Query Command /options"
    case update.callback_query.data do
      "/options join_zone" ->
        Out.advance_fsm(update, :goto_zone_register)
        answer_callback_query text: "Joining zone"
        send_message "What's the zone id? ", reply_markup: %Model.ForceReply{force_reply: true}
      "/options songs_in_zone" ->
        with %User{participants: %Participant{} = participant }  <- Accounts.get_simple_user_by_telegram_id(update.callback_query.from.id) do
#TODO add zone id to callback data and send messages with rating possibility
          send_message("Which songs do you wish to see?", reply_markup:%Model.InlineKeyboardMarkup{
                inline_keyboard: [
                  [
                    %{
                      callback_data: "/song all",
                      text: "All",
                    },
                    %{
                      callback_data: "/song unplayed",
                      text: "Unplayed",
                    },

                  ],
                  []
                ]
}

)
        else
          _ ->
          send_message "Currently not in zone"
        end
        answer_callback_query text: "TODO SHOW SONGS IN ZONE"
      "/options request_song" ->
        answer_callback_query text: "TODO request song query"
      "/options edit_info" ->
        send_message "What do you want to edit?", reply_markup: @options_menu
        answer_callback_query text: "Edit Info"
    end
  end

  reply do
    {pid, state} = Out.pid_and_state_from_update(update)
    case state do
      :zone_register ->
        Out.update_zone(pid, update.message.text, update) |> send_message
        Out.post_action(update, pid)
      :ask_password ->
        Out.join_zone(update, pid, update.message.text) |> send_message
      :ask_value ->
          Out.update_value(pid, update.message.text) |> send_message
      _ -> send_message "not doing anything?"
    end
  end


  contact do
    {pid, state} = Out.pid_and_state_from_update(update)
    to_edit = FsmServer.to_edit(pid)
    if state == :ask_value and to_edit == :phone do
      Out.update_value(pid,  update.message.contact.phone_number) |> send_message
    end
  end

  message do
    Logger.log :warn, "Did not match the message"
    {pid, state} = Out.pid_and_state_from_update(update)
    send_message to_string(state)
    case  state do
      :polling -> send_message "What do you want to do?",
      reply_markup: @default_menu
      _ ->
          Out.return_to_polling(pid)
    end
  end
end
