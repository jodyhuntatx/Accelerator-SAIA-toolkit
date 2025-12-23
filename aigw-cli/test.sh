#!/bin/bash

ADD_FILE="./add_agent.json"
UPD_FILE="./update_agent.json"
agent_name1=$(cat $ADD_FILE | jq -r .name)

echo; echo "Adding agent named \"$agent_name1\" using file $ADD_FILE..."
./aigw-cli.sh add ./add_agent.json

echo; echo "Lookup agent by name. This should return 1 record."
agent_rec=$(./aigw-cli.sh loo name "$agent_name1")
echo $agent_rec | jq .
echo "Records expected: 1 Records returned: $(echo $agent_rec | jq '. | length')"

# Get agent ID and created_by from the agent record
agent_id1=$(echo $agent_rec | jq -r .[].id)
created_by=$(echo $agent_rec | jq -r .[].createdBy)

echo; echo "Lookup agent by ID. This should return 1 record."
agent_rec=$(./aigw-cli.sh loo id "$agent_id1")
echo $agent_rec | jq .
echo "Records expected: 1 Records returned: $(echo $agent_rec | jq '. | length')"

echo; echo "Lookup agent by createdBy. This should return at least 1 record."
agent_rec=$(./aigw-cli.sh loo createdBy "$created_by")
echo $agent_rec | jq .
echo "Records expected: >=1 Records returned: $(echo $agent_rec | jq '. | length')"

# Use agent ID to update the agent, this should succeed
# and will change the agent's name, description, owner, callback URL and tags
echo; echo "Updating agent ID \"$agent_id1\" using file $UPD_FILE..."
agent_name2=$(cat $UPD_FILE | jq -r .name)
./aigw-cli.sh upd $agent_id1 $UPD_FILE

# Update changes name, lookup by original name should fail
echo; echo "Looking up agent by original name. This should return 0 records."
agent_rec=$(./aigw-cli.sh loo name "$agent_name1")
echo $agent_rec | jq .
echo "Records expected: 0 Records returned: $(echo $agent_rec | jq '. | length')"

# Add second agent, this should succeed
echo; echo "Adding agent named \"$agent_name1\" using file $ADD_FILE..."
agent_rec=$(./aigw-cli.sh add ./add_agent.json)
echo $agent_rec | jq .
agent_id2=$(echo $agent_rec | jq -r .id)

# Should be at least two agents
echo; echo "Looking up agents created by user. This should return at least 2 records."
agent_recs=$(./aigw-cli.sh look createdBy $created_by)
echo $agent_recs | jq '.[].name'
echo "Records expected: >=2 Records returned: $(echo $agent_recs | jq '. | length')"

# Delete agents by id
echo; echo "Deleting test agents..."
./aigw-cli.sh del $agent_id1
./aigw-cli.sh del $agent_id2

echo; echo "Confirming agents are deleted..."
echo "Looking up agent $agent_name1..."
./aigw-cli.sh loo name "$agent_name1"
echo "Looking up agent $agent_name2..."
./aigw-cli.sh loo name "$agent_name2"