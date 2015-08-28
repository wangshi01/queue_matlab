function  predictedChannelState = predictChannel(realChannelState,probMissDetection,probFalseAlarm);
%PREDICTCHANNEL calculate the result of SU sense the channel
%   given probability of miss detection and False alarm , to get the guess of channel occupancy with real channel occupancy
BUSYSTATE = 1;
FREESTATE = 2;
switch realChannelState
    case BUSYSTATE
        if rand() < probMissDetection
            predictedChannelState=FREESTATE;
        else
            predictedChannelState=BUSYSTATE;
        end
    case FREESTATE
        if rand() < probFalseAlarm
            predictedChannelState=BUSYSTATE;
        else
            predictedChannelState=FREESTATE;
        end
    otherwise
        predictedChannelState=BUSYSTATE;
end
end

