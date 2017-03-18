% function to interpolate
%f = @(t) sin(2*pi*200e3*t);
f = @(t) sin(2*pi*180e3*t).*(1+sin(20*pi*2e3*t));
%f = @(t) sin(2*pi*180e3*t).*(1+sin(2*pi*2e3*t))+sin(2*pi*100e3*t).*(1+sin(2*pi*20e3*t))+sin(2*pi*50e3*t).*(1+sin(2*pi*25e3*t));

% sampling parameters
Fs = 500e3;
Ts = 1/Fs;
Ns = 32;
t = Ts*(0:Ns-1);

% filter parameters
N = 512;
Ni = 32;
tt = Ts/Ni*(0:Ni*Ns-1);
d = fdesign.lowpass('N,Fp,Ap,Ast', N, 0.8/Ni, 0.01, 80);
FIR = design(d, 'equiripple');

input = upsample(f(t), Ni);
%input = f(tt);
output = Ni*filter(FIR, input);

% remove delay samples
sampled = input(1:end-N/2);
tt = tt(1:end-N/2);
input = f(tt);
output(1:N/2) = [];

% plot selected range
xx = 512;
Nx = numel(input)/2;
tt = Ts/Ni*(-xx/2:xx/2-1);
input = input(Nx-xx/2:Nx+xx/2-1);
sampled = sampled(Nx-xx/2:Nx+xx/2-1);
output = output(Nx-xx/2:Nx+xx/2-1);

tt2 = tt;
idx = sampled==0;
sampled(idx)=[];
tt2(idx)=[];

plot(tt, input, tt2, sampled, 'r', tt, output, 'bo');
legend('input', 'samples', 'output');
xlabel('time (s)');
ylabel('amplitude (V)');
