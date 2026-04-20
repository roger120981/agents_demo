defmodule AgentsDemo.Agents.AgentPersistence do
  @moduledoc """
  Implements `Sagents.AgentPersistence` for state snapshots.

  Persists full agent state (messages, todos, metadata) to the database
  via `AgentsDemo.Conversations.save_agent_state/2`.
  """

  @behaviour Sagents.AgentPersistence

  require Logger

  @impl true
  def persist_state(agent_id, state_data, context) do
    conversation_id = extract_conversation_id(agent_id)

    case AgentsDemo.Conversations.save_agent_state(conversation_id, state_data) do
      {:ok, _} ->
        Logger.debug("Persisted agent state for #{agent_id} (#{context})")
        :ok

      {:error, %Ecto.Changeset{errors: errors}} = error ->
        if conversation_deleted?(errors) do
          Logger.warning(
            "Skipping agent state persistence for #{agent_id} (#{context}): conversation no longer exists"
          )

          :ok
        else
          error
        end
    end
  end

  @impl true
  def load_state(agent_id) do
    conversation_id = extract_conversation_id(agent_id)
    AgentsDemo.Conversations.load_agent_state(conversation_id)
  end

  defp extract_conversation_id(agent_id) do
    String.replace_prefix(agent_id, "conversation-", "")
  end

  defp conversation_deleted?(changeset_errors) do
    Enum.any?(changeset_errors, fn
      {:conversation_id, {_msg, opts}} -> Keyword.get(opts, :constraint) == :foreign
      _ -> false
    end)
  end
end
