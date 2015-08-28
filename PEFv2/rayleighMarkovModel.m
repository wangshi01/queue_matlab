function [ ProbMatrix,...%( numSU * numChannel * numState * numState)
    stateProb... %( numSU * numChannel * numState)
    ] = rayleighMarkovModel(numSU,numChannel,Ptarget,avgSNR,DopplerFeq,PacketTime) % (numSU * numChannel)
%MYFUN2 Markov model of a rayleigh channel
%   此处显示详细说明
%% parameter settings
a = [274.7229	90.2514	67.6181	50.1222	53.3987	35.3508];
g = [7.9932	3.4998	1.6883	0.6644	0.3756	0.09];
numState = length(a);% number of states

%% transtion probability matrix (numSU*numChannel*numState*numState) and steady-state probability vector(numSU*numChannel*numState)

tp = zeros(numSU,numChannel,numState,numState); %the transition probability matrix
stateProb = zeros(numSU,numChannel,numState); % the state probability vector of size K

for iSU=1:numSU
    for iChannel=1:numChannel
        SNRboundary = [0 1./g.*log(a./Ptarget(iSU,iChannel))];
        ratioSNRboundaryToavgSNR = SNRboundary./avgSNR(iSU,iChannel);
        
        for iState = 1:numState
            stateProb(iSU,iChannel,iState) = exp(-ratioSNRboundaryToavgSNR(iState)) - exp(-ratioSNRboundaryToavgSNR(iState+1));
        end
        
        % carrier frequency 1.9e10 Hz, packet size 384 bits, speed 5 km/h,
        % transmission rate 1Mb/s
        % DopplerFeq=8.7963;
        % PacketTime=3.84e-3;
        for iState = 1:numState
            if iState<=numState-1
                tp(iSU,iChannel,iState,iState+1)=transprob( stateProb(iSU,iChannel,iState),PacketTime(iSU,iChannel),ratioSNRboundaryToavgSNR(iState+1),DopplerFeq(iSU,iChannel));
            end
            if iState>=2
                tp(iSU,iChannel,iState,iState-1)=transprob( stateProb(iSU,iChannel,iState),PacketTime(iSU,iChannel),ratioSNRboundaryToavgSNR(iState),DopplerFeq(iSU,iChannel));
            end 
                tp(iSU,iChannel,iState,iState)=1-sum(tp(iSU,iChannel,iState,:));
        end
    end
end

ProbMatrix=tp;
end

function p = transprob(piK,Tp ,ratio,fm)
%TRANSPROB 此处显示有关此函数的摘要
%   此处显示详细说明
n=sqrt(2*pi*ratio)*fm*exp(-ratio);
p=n*Tp/piK;
end