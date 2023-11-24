alias Bloodhound.Repo
alias Bloodhound.Schemas.Chains.{Chain, ChainEvent}

# Start Event
start_event = %ChainEvent{
  event_type: "test.StartEvent",
  type: "kafka",
  key_field: "attempt_id"
}
|> Repo.insert!

# End Event
end_event = %ChainEvent{
  event_type: "test.EndEvent",
  type: "kafka",
  key_field: "attempt_id"
}
|> Repo.insert!

# Chain
chain = %Chain{
  name: "Invoke Chain",
  description: "A chain that tracks the invoke process",
  timeout: 60000,  # 1 minute in milliseconds
  initial_event_type: "test.StartEvent",
  chain_events: [start_event, end_event]
}
|> Repo.insert!

