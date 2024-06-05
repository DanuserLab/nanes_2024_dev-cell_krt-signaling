function theta = bnAngdiff(alpha,beta)
%BNANGDIFF Difference between angles, in radians
%   Inputs on [-pi,pi]; output on [0,pi];
    t1 = abs(alpha - beta);
    t2 = 2*pi - t1;
    theta = min(t1, t2); 
end
