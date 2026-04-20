defmodule AgentsDemo.Agents.AgentPersistenceTest do
  use AgentsDemo.DataCase

  import AgentsDemo.AccountsFixtures
  import AgentsDemo.ConversationsFixtures
  import ExUnit.CaptureLog

  alias AgentsDemo.Agents.AgentPersistence
  alias AgentsDemo.Conversations

  describe "persist_state/3" do
    test "persists state for an existing conversation" do
      conversation = conversation_fixture()
      agent_id = "conversation-#{conversation.id}"
      state_data = %{"version" => 1, "messages" => []}

      assert :ok = AgentPersistence.persist_state(agent_id, state_data, :on_completion)
      assert {:ok, ^state_data} = Conversations.load_agent_state(conversation.id)
    end

    test "returns :ok and logs a warning when the conversation was deleted" do
      scope = user_scope_fixture()
      conversation = conversation_fixture(scope: scope)
      agent_id = "conversation-#{conversation.id}"
      state_data = %{"version" => 1, "messages" => []}

      {:ok, _} = Conversations.delete_conversation(scope, conversation.id)

      log =
        capture_log(fn ->
          assert :ok = AgentPersistence.persist_state(agent_id, state_data, :on_shutdown)
        end)

      assert log =~ "Skipping agent state persistence"
      assert log =~ agent_id
      assert log =~ "conversation no longer exists"
    end
  end
end
