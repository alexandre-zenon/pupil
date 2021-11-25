function [Y]= diff2pt(fe,X,n)


%Two points algorythm differentiator 
%[Y]= diff2pt(fe,X,{n})
%
% fe is the sampling frequency
%X is the data matrix to differentiate; X has to be a column vector
%n is the size of the differentiation window; this parameter is optional
%default values for n is 2 
%cutoff value = 0.443 / (2 * n * T) with T = 1/fe
%for n = 2 cutoff values is 11 Hz at 100 Hz sampling rate
     
  
if nargin == 2
    n=2; 
end    


[L,C]= size(X);
if C ~= 1
    error('X must be a single column vector');
end    



%Add n points before and after for differentiation
D= [];
premier= X(1);
dernier= X(L);

for i = 1 : n
    D= [D; premier];
end   
D= [D; X];


for i = 1 : n
    D= [D ; dernier];
end 




%Differentiation 
Y= [];
T= 1/fe;
val= n + L;

for i = n+1 : val
    tampon= ( D(i+n) -  D(i-n) ) / (2 * n * T);
    Y= [Y ; tampon];
end    

