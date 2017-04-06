t = 0:1023;
T = 512;
f = @(t) 2048 + 1024*sin(2*pi*t/T).*exp(-t/(2*T));

%plot(t, f(t-8));

fid = fopen('test_signal1.txt', 'w');
for i = t
    fprintf(fid, '%012s\n', dec2bin(f(i-8)));
end
fclose(fid); % close your file
