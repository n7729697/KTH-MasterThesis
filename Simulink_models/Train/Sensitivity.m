% Load RL environment and agent (replace with your RL setup)
load('savedAgents\agent_2023_September_23_22_22.mat');

%%
% Define initial state or observation (replace with your specific initial data)
initial_observation = [0.5, 0.2, 0.8];

% Run the RL agent to get the initial action
initial_action = rl_agent.getAction(initial_observation);

% Define a small perturbation for the input
epsilon = 0.01;

% Perturb the input observation
perturbed_observation = initial_observation + epsilon * randn(size(initial_observation));

% Ensure the perturbed observation is within valid bounds (if necessary)
perturbed_observation = clampToBounds(perturbed_observation, observation_bounds);

% Run the RL agent with the perturbed observation
perturbed_action = rl_agent.getAction(perturbed_observation);

% Calculate the sensitivity of the RL agent
sensitivity = norm(initial_action - perturbed_action);

% Display the results
fprintf('Initial Action: %.4f\n', initial_action);
fprintf('Perturbed Action: %.4f\n', perturbed_action);
fprintf('Sensitivity: %.4f\n', sensitivity);


function clamped_value = clampToBounds(value, min_value, max_value)
    clamped_value = min(max(value, min_value), max_value);
end
