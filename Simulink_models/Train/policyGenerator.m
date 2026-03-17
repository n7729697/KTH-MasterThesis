% clear

policyDirectory = 'savedAgents\';
policyName = 'agent_2023_September_23_22_22.mat';

load(append(policyDirectory, policyName))
if exist('saved_agent','var')
    agent = saved_agent;
end
agent.AgentOptions.UseDeterministicExploitation = 1;

generatePolicyFunction(agent)
% generatePolicyBlock(agent)
% a state to be evaluated
randObs = rand(getObservationInfo(agent).Dimension);
evaluatePolicy(randObs)

% rename the generated policy
% movefile('blockAgentData.mat',policyName)
