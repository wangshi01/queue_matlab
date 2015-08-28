function currentState = nextState( numOfState, previousState, transProbMatrix)
%NEXTSTATE return the current state given previous state and the
%transmission matrix.
%   transProbMatrix is numOfState*numOfState matrix. transProbMatrix(m,n)is
%   the probability currentState is n given previousState is m.
	p    =rand();% roll the dice
	prob =zeros(1,numOfState+1);
      
    for i = 1:numOfState
       prob(i+1) = prob(i) + transProbMatrix(previousState,i);
       if p>prob(i) && p<=prob(i+1)
           currentState = i;
       end
    end
end

