

isUsePretrainedAgent = 1;
isUseExtAct = 0;
mdl = 'RLtest_2021b';
SaveAgentReward = 100;
StopTrainReward = 120;
DiscountFactor = 0.98;
criticLearnRate = 1e-3; %2
actorLearnRate = 5e-4; %1

% robot animation on/off
set_param(mdl,'SimMechanicsOpenEditorOnUpdate','on') 

numAct = 4;
% Obs include: #rot x,y,z #v x,y,z #fn: FR,FL,RL,RR
numObs = 10 + numAct;

% Normalization
load("norm_para_all.mat")
state_init = [0	0 0	0 0 0 0.5 0.5 0.5 0.5];
x_norm_init=(state_init - y_norm_min)./y_norm_range;

% Robot settings
alpha_r_gain = 0;
alpha_b_gain = pi/5;
z_l_gain = 8e-3;

% Robot runtime
Tf = 5;
Ts = 0.05;

% added in amplitude 1
rotVariance = 0; % 0.001
fnVariance = 0; % 0.002
speedVariance = 0; % 0.001
agent.AgentOptions.UseDeterministicExploitation = 1;

VRef = 0.2; % reference velocity

EntropyWeight = 1;
% EntropyLearnRate = 1e-4;
TargetEntropy = -numAct*1;

maxEpisodes = 400;

maxSteps = floor(Tf/Ts);

% doTraining = 0; % if not train, noise is disabled

% startAgentTime = 32*Ts;
isCheckDone = 1;
isContactBoolean = 1;

actInfo = rlNumericSpec([numAct 1],'LowerLimit',0,'UpperLimit', 1);
actInfo.Name = 'actions';

obsInfo = rlNumericSpec([numObs 1]);
obsInfo.Name = 'observations';

blk = [mdl, '/RL Agent'];
env = rlSimulinkEnv(mdl,blk,obsInfo,actInfo,'UseFastRestart','on');

entropyListSize = maxSteps*maxEpisodes;
EntropyList = zeros(entropyListSize, 1);
EntropyList(1)=TargetEntropy;

EntropyWeightList = zeros(entropyListSize, 1);
EntropyWeightList(1)=EntropyWeight;

simout = sim(mdl);
save("Vref053.mat",'simout')