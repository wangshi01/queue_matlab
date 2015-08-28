function [ performanceEF] = PEFv2( ...
    numSU,...                               % number of secondary user(1*1)
    numChannel,...                          % number of channel(1*1)
    arrivalRate,...                         % arrival rate of SU (1* numSU)
    bufferSize,...                          % buffer size of SU (1*numSU)
    probMissDetection,...                   % channel sensing miss detection ratio (numSU * numChannel)
    probFalseAlarm,...                      % channel sensing false alarm ratio (numSU * numChannel)
    probDistribution,...                    % channel resourse allocation probabilities (numSU * numChannel)
    busyToBusy,freeToFree,...               % PU activity transmission probabilities (1 * numChannel)
    Ptarget,avgSNR,dopplerFeq,packetTime... % channel condition state parameters (numSU * numChannel)
    )
% PEFv2 Calculate the performance evaluation function multi-user multi-channel
%   debug version. parameter checked: ,numArrival,numInQueue,numDeparture,numLost,numReject,ProbMatrix,actualCap 
%  change the way how channel is allocated.
%% call function
% nextState
% predictChannel
% rayleighMarkovModel

%% parameters settings
Nsim = 5000; % simulation length
%% number of packets arrival ( numSU * Nsim )
numArrival = zeros(numSU,Nsim);
for iSU = 1:numSU
    numArrival(iSU,:) = random('poisson',arrivalRate(iSU),[1,Nsim]);
end
%% STEP 1: PU state: channel occupancy situation  PUState(numChannel * Nsim)
BUSYSTATE = 1;
FREESTATE = 2;
PUState   = ones(numChannel,Nsim);
 
% init state
initPUState = ones(numChannel,1); % set initial PU state = BUSYSTATE = 1;
% calculate each state
for iChannel = 1:numChannel
    PUState(iChannel,1) = initPUState(iChannel);
    for iTS = 2:Nsim
        PUState(iChannel,iTS) = nextState(2, PUState(iChannel,iTS-1), ...
            [busyToBusy(iChannel),1-freeToFree(iChannel);1-busyToBusy(iChannel),freeToFree(iChannel)]);   
    end
end
%% STEP 2: SU predict PU state predictedPUState(numSU * numChannel * Nsim)
predictedPUState = ones(numSU,numChannel,Nsim);

for iSU = 1:numSU
    for iChannel = 1:numChannel
        for iTS = 1:Nsim
            predictedPUState(iSU,iChannel,iTS) = predictChannel(PUState(iChannel,iTS),probMissDetection(iSU,iChannel),probFalseAlarm(iSU,iChannel));
        end
    end
end
%% STEP 3: channel condition state channelConditionState(numSU * numChannel * Nsim) & serviceCap(numSU * numChannel * Nsim) & actualCap(numSU * numChannel * Nsim)
% initial state
channelConditionState   = ones(numSU,numChannel,Nsim);
StateNum                = 6;
StateToCap              = [2 4 6 9 12 18];  %[0.5 1 1.5 2.25 3 4.5]
serviceCap              = zeros(numSU,numChannel,Nsim);  % channel capacity:number of packets can be sent
actualCap               = zeros(numSU,numChannel,Nsim);
[ProbMatrix, stateProb] = rayleighMarkovModel( numSU,numChannel,Ptarget,avgSNR,dopplerFeq,packetTime);


for iChannel = 1:numChannel
    for iSU = 1:numSU
        channelConditionState(iSU,iChannel,1) = 1; % set the initial channel condition state =1
    end
end

channelDistribution = zeros(numSU,numChannel,Nsim);  % variable distribe how the channel allocated.

for iTS = 2:Nsim
    for iChannel = 1:numChannel
        p = rand();
        prob = zeros(1,numSU);
        for iSU = 1:numSU
            prob(iSU+1) = prob(iSU) + probDistribution(iSU,iChannel);
            if p > prob(iSU) && p < prob(iSU+1)
                channelDistribution(iSU,iChannel,iTS)=1;
                continue;
            end
        end
        for iSU = 1:numSU
            channelConditionState(iSU,iChannel,iTS) = ...
            nextState(StateNum,channelConditionState(iSU,iChannel,iTS-1),squeeze(ProbMatrix(iSU,iChannel,:,:)));
            serviceCap(iSU,iChannel,iTS) = StateToCap(channelConditionState(iSU,iChannel,iTS));

            if predictedPUState(iSU,iChannel,iTS) == BUSYSTATE
                actualCap(iSU,iChannel,iTS) = 0;
            else
                actualCap(iSU,iChannel,iTS) = channelDistribution(iSU,iChannel,iTS).*serviceCap(iSU,iChannel,iTS);
            end
        end
    end
end

%% queue dynamic time slot by time slot
% numLost,numReject,numInQueue,numDeparture,numWaste
numInQueue   = zeros(numSU,Nsim);
numReject    = zeros(numSU,Nsim);

numDeparture = zeros(numSU,numChannel,Nsim);% packet depart at each channel
numWaste     = zeros(numSU,numChannel,Nsim);% capacity waste at each channel
numLost      = zeros(numSU,numChannel,Nsim);% packet loss by collision

% channel capability

for iTS=1:Nsim
%% packet departure and loss phase
    for iSU=1:numSU 
        if numInQueue(iSU,iTS) < sum(actualCap(iSU,:,iTS))% ÐÅÏ¢ÈÝÁ¿´óÓÚÊ£ÓàµÄpacketÊýÁ¿,°´ÕÕÐÅµÀÈÝÁ¿±ÈÀý£¬·ÖÅäËù·¢ËÍµÄpacket
            numInQueueAfterDeparture = 0;
            for iChannel=1:numChannel
                numDeparture(iSU,iChannel,iTS) = numInQueue(iSU,iTS).*(actualCap(iSU,iChannel,iTS)./sum(actualCap(iSU,:,iTS)));%departure °´ÕÕcapÔÚ¸÷¸öÐÅµÀµÄ±ÈÀý·ÖÅä
                numWaste(iSU,iChannel,iTS) = actualCap(iSU,iChannel,iTS) - numDeparture(iSU,iChannel,iTS);
                if PUState(iChannel,iTS) == BUSYSTATE && predictedPUState(iChannel,iTS) == FREESTATE
                    numLost(iSU,iChannel,iTS)= numDeparture(iSU,iChannel,iTS);
                end
            end
        else
            numInQueueAfterDeparture = numInQueue(iSU,iTS) - sum(actualCap(iSU,:,iTS));
            for iChannel=1:numChannel
                numDeparture(iSU,iChannel,iTS) = actualCap(iSU,iChannel,iTS);
                if PUState(iChannel,iTS) == BUSYSTATE && predictedPUState(iChannel,iTS) == FREESTATE
                    numLost(iSU,iChannel,iTS)= numDeparture(iSU,iChannel,iTS);
                end
            end
        end
    
%% packet arrival phase
        if numArrival(iSU,iTS) > bufferSize(iSU) - numInQueueAfterDeparture 
            numInQueue(iSU,iTS+1) = bufferSize(iSU);
            numReject(iSU,iTS) = numArrival(iSU,iTS) + numInQueueAfterDeparture - bufferSize(iSU);
        else
            numInQueue(iSU,iTS+1) = numInQueueAfterDeparture + numArrival(iSU,iTS);
            numReject(iSU,iTS) = 0;
        end
    end
end


performanceEF=(sum(sum(sum(numLost)))+sum(sum(numReject)))./Nsim; % performance evaluation function is expectation of paket loss rate + packet rejected number.
end