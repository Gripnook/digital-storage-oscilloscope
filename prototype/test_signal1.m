t = 0:511;
T = 256;
f = @(t) 2048 + 1024*sin(2*pi*t/T).*exp(-t/(2*T));

%plot(t, f(t));

fid = fopen('../src/test_signal1.txt', 'w');
for i = t
    fprintf(fid, '%012s\n', dec2bin(f(i)));
end
fclose(fid); % close your file
