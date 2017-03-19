t = 0:511;
T = 256;
f = @(t) 2048 + 1024*square(2*pi*(t-64)/T);

%plot(t, f(t));

fid = fopen('test_signal2.txt', 'w');
for i = t
    fprintf(fid, '%012s\n', dec2bin(f(i)));
end
fclose(fid); % close your file
