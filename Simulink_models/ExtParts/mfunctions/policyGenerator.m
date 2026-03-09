clear

policyDirectory = 'C:\Users\qinglei\Box\MyDrive\KTH\My Research\Quadruped_robot_simu\robotLearning\resultsAnalysis\Vref035-02 (opti)\';
policyName = 'Agent293.mat';

load(append(policyDirectory, policyName))
if exist('saved_agent','var')
    agent = saved_agent;
end
agent.AgentOptions.UseDeterministicExploitation = 1;

generatePolicyFunction(agent)

% rename the generated policy
movefile('agentData.mat',policyName)

% randObs = rand(getObservationInfo(agent).Dimension);
% evaluatePolicy(randObs)

